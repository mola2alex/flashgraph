package mathlib.expr {
	import mathlib.expr.datatype.Token;
	import mathlib.expr.datatype.TokenType;
	import mathlib.expr.datatype.ParseTree;
	
	/**
	* Generates a ParseTree from an array of Tokens. The parser handles a
	* grammar with infix arithmetic operators and function application. Implied
	* multiplication is handled in the Lexer, so that the end result is an
	* expression syntax not unlike that understood by TI calculators.
    * For example, the following are true in an Environment with three
    * independent variables, x, y and z:
	* <pre>
	*  xysin(x) == x ~~ y ~~ sin(x)
	*  xx == x ~~ x
	*  2z(x + y) = 2 ~~ z ~~ (x + y)
	*  3max(x^2y, y^2x) == 3 ~~ max(x^2 ~~ y, y^2 ~~ x)
	* </pre>
	*
	* The complete grammar in BNF is as follows. Lower-case terminals such as
	* <code>[addop]</code> correspond to TokenTypes.
	* <pre>
	*  [Expression] ::= [Term]
	*                 | [Expression] [addop] [Term] <br/>
	*
	*       [Term] ::= [Factor]
	*                 | [Term] [mulop] [Factor] <br/>
	*
	*     [Factor] ::= [negate] [Factor]
	*                 | [Datum]
	*                 | [Datum] [pow] [Factor] <br/>
	*
	*      [Datum] ::= [var]
	*                 | [number]
	*                 | [const]
	*                 | [Function]
	*                 | [lp] [Expression] [rp] <br/>
	*
	*   [Function] ::= [fnname] [lp] [Arguments] [rp]
	*                 | [fnname] [lp] [rp] <br/>
	*
	*  [Arguments] ::= [Expression]
	*                 | [Expression] [comma] [Arguments]
	* </pre>
	*/
	public class Parser {
		/** A local copy of the tokens we're working on. */
		private static var tokens:Array;
		
		/**
		* Parse the given array of Tokens and generate a ParseTree representing
		* the expression.
		* @param _tokens An array of Tokens representing a tokenized expression.
		*  This may be generated by <code>Lexer.lex()</code>.
		* @throws SyntaxError <code>SyntaxError</code>: The given expression is
		*  not valid. The <code>message</code> member of the exception contains
		*  a hint at what went wrong.
		* @see Lexer#lex
		*/
		public static function parse(_tokens:Array):ParseTree {
			var pt:ParseTree;

			// Make a local copy of the token array--we're going to consume
			// its elements.
			tokens = _tokens.concat();

			// Try to parse it as an expression.
			pt = parseE();

			// If we didn't consume all the tokens, something's amiss.
			if(tokens.length != 0)
				throw new SyntaxError("unexpected token(s) after end of expression: " + tokens.toString());

			return pt;
		}
		
		/** Parse an expression from the local tokens array. */
		private static function parseE():ParseTree {
			var eparse:ParseTree, temppt:ParseTree;
			
			// First, parse a term.
			eparse = parseTM();
			
			// Then, while we have an addop, make a new parent branch for the
			// stuff we just parsed, and tack things on the top as appropriate.
			// This way, we get left-association for addition, so things like
			// 1-2+3 get parsed as
			//     +
			//    / \
			//   -   3
			//  / \
			// 1   2
			while(tokens.length != 0 && tokens[0].type == TokenType.ADDOP) {
				temppt = eparse;
				eparse = new ParseTree(tokens.shift(), false); // the false specifies that the node will definitely have children
				eparse.appendChild(temppt);
				eparse.appendChild(parseTM());
			}
			
			return eparse;
		}
		
		/** Parse a term from the local tokens array. */
		private static function parseTM():ParseTree {
			var tmparse:ParseTree, temppt:ParseTree;
			
			// Parse a factor.
			tmparse = parseF();
			
			// Same left-association deal as with parseE.
			while(tokens.length != 0 && tokens[0].type == TokenType.MULOP) {
				temppt = tmparse;
				tmparse = new ParseTree(tokens.shift(), false);
				tmparse.appendChild(temppt);
				tmparse.appendChild(parseF());
			}

			return tmparse;
		}

		/** Parse a factor from the local tokens array. */
		private static function parseF():ParseTree {
			var fparse:ParseTree, temppt:ParseTree;
			
			if(tokens.length == 0)
				throw new SyntaxError("expected a factor");
			
			// F => -F production
			if(tokens[0].type == TokenType.NEGATE) {
				fparse = new ParseTree(tokens.shift());
				fparse.appendChild(parseF());
			}
			else {
				// F => DAT production
				fparse = parseDAT();
				
				// Exponentiation associates to the right, we tack further
				// exponentiations on the bottom of the root node, unlike
				// addition and multiplication in parseE and parseTM.
				if(tokens.length != 0 && tokens[0].type == TokenType.POW) {
					temppt = fparse;
					fparse = new ParseTree(tokens.shift());
					fparse.appendChild(temppt);
					fparse.appendChild(parseF());
				}
			}
			
			return fparse;
		}
		
		/** Parse a function from the local tokens array. */
		private static function parseFN():ParseTree {
			var head:Token, arity:int, i:int, fnparse:ParseTree;
			
			// First, grab a function from the token stream and make a tree
			// with it as its root.
			head = eatMandToken(TokenType.FN);
			arity = head.val.length;  // Little known fact: a Function's length is its arity
			fnparse = new ParseTree(head);
				
			// Then a (
			eatMandToken(TokenType.LP, "Functions must be followed with by an opening parenthesis.");
			
			if(arity > 0) {
				// Parse one argument...
				fnparse.appendChild(parseE());
			
				// Then a comma, then the next, and so on, until we've hit the
				// arity of the function.
				for(i = 1; i < arity; i++) {
					eatMandToken(TokenType.COMMA, "Too few arguments to a function?");
					fnparse.appendChild(parseE());
				}
			}
			
			eatMandToken(TokenType.RP, "Too many arguments to a function?");
			
			return fnparse;
		}
				

		/** Parse a datum from the local tokens array. */
		private static function parseDAT():ParseTree {
			var eparse:ParseTree;
			
			if(tokens.length == 0)
				throw new SyntaxError("expected a datum");
			
			switch(tokens[0].type) {
				case TokenType.VAR:
				case TokenType.NUM:
				case TokenType.CONST:
					return new ParseTree(tokens.shift());
					
				case TokenType.FN:
					return parseFN();
				
				case TokenType.LP:
					tokens.shift();
					eparse = parseE();
					eatMandToken(TokenType.RP, "Mismatched parentheses.");
					return eparse;
					
				default:
					throw new SyntaxError("expected a datum");
			}
		}
		
		/**
		* Return the head token of the local token array if it matches the
		* given type, otherwise throw a SyntaxError with the given message.
		*/
		private static function eatMandToken(type:TokenType, hint:String = ""):Token {
			var errStr:String;
			
			if(tokens.length == 0 || tokens[0].type != type) {
				errStr = "expected " + type.toString();
				if(hint) errStr += " - " + hint;
				throw new SyntaxError(errStr);
			}
			
			return tokens.shift();
		}

	}
}
