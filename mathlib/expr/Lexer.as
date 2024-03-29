package mathlib.expr {
	import flash.utils.Dictionary;
	import mathlib.expr.datatype.Token;
	import mathlib.expr.datatype.TokenType;

	/** 
	* Generates an array of Tokens from a string expression. Note that this
	* may not be a one-to-one representation of the incoming string; whitespace
	* is insignificant and implicit multiplication operators are inserted where
	* appropriate if the <code>doImplicitMult</code> flag in the Environment is
	* true. For example, the lexer would make the following conversions in an
	* Environment with independent variables x and y:
	* <pre>
	*  xy => x ~~ y
	*  xsin(y) => x ~~ sin(y)
	*  sin(x)exp(y) => sin(x) ~~ exp(y)
	* </pre>
	* If <code>doImplicitMult</code> were false, the above examples would
	* generate errors.
	*/
	public class Lexer {
		// Local copies of the Environment, token array, and given string.
		private static var env:Environment;
		private static var tokens:Array;
		private static var s:String;

		// Regular expressions for matching ids, numbers, alphanumerics, and
		// possible first characters of a number.
		private static var idRegex:RegExp = /^([A-Za-z_][A-Za-z_0-9]*)(.*)/s;
		private static var numRegex:RegExp = /^([0-9]*\.?[0-9]+)(.*)/s;
		private static var alphaRegex:RegExp = /^[A-Za-z_]/;
		private static var simplenumRegex:RegExp = /^[0-9.]/;

		
		/**
		* Lex the given string and return an array of Tokens representing it.
		* @param _env The Environment to use to look up functions, operators,
		*  constants, and variable names.
		* @param _s The string representing the expression to tokenize.
		* @throws SyntaxError <code>SyntaxError</code>: An unknown token was
		*  encountered. The <code>message</code> member of the exception gives
		*  more detail about the error.
		* @see mathlib.expr.datatype.Token
		*/
		public static function lex(_env:Environment, _s:String):Array {
			env = _env;
			s = eatSpaces(_s);
			tokens = new Array();
			
			while(s.length > 0)
				realLex();
			
			return tokens;
		}
		
		/**
		* Lex the internal expression string one token at a time, accumulating
		* results in <code>tokens</code>. This consumes characters from
		* <code>s</code>.
		*/
		private static function realLex():void {
			if(s.length == 0) return;
			
			switch(s.charAt(0)) {
				case "(":
					addImplicitMult();
					pushNewToken(TokenType.LP);
					s = s.substring(1);
					return;
					
				case ")":
					pushNewToken(TokenType.RP);
					s = s.substring(1);
					return;
				
				case ",":
					pushNewToken(TokenType.COMMA);
					s = s.substring(1);
					return;
				
				case "-":
					lexMinus();
					return;
			}
			
			if(idRegex.test(s))
				lexId();
		
			// The minus lexer considers negative numbers to be applications of
			// the negate operator. The compiler optimizes these back to normal
			// numbers if possible.
			else if(simplenumRegex.test(s))
				lexNum();
			
			// This could use cleanup...
			else {
				try {
					lexOp();
				} catch(err:SyntaxError) {
					throw new SyntaxError("invalid input: " + s);
				}
			}
		}
		
		/// Helper function to append a new token of the given type and value.
		private static function pushNewToken(_type:TokenType, _val:* = undefined):void {
			tokens.push(new Token(_type, _val));
		}
		
		/**
		* Add in a multiplication token if appropriate. Things like "sin(x)" are
		* distinguished from "x(2)" by not inserting a multiplication if the
		* previous token was a function. 
		* @param numOK If this is true, we insert the multiplication if the
		*  previous token was a number. This is a problem only when we have two
		*  numbers side by side -- this is a parse error, and adding a
		*  multiplication between them would hide that fact.  E.g., since space
		*  is insignificant, it would let input like "0.2341.242" slide as
		*  0.2341 * 0.242.
		*/
		private static function addImplicitMult(numOK:Boolean = true):void {
			if(!env.doImplicitMult || tokens.length == 0) return;
			
			// The decision depends on the type of the previous token, so grab
			// that.
			var lastType:TokenType = tokens[tokens.length - 1].type;
		
			if(lastType == TokenType.RP    ||			// ...)x --> ...) * x
			   lastType == TokenType.VAR   ||			// xy    --> x * y
			   lastType == TokenType.CONST ||			// pix   --> pi * x
			   (numOK && lastType == TokenType.NUM))	// 2x    --> 2 * x
				pushNewToken(TokenType.MULOP, env.implicitMulOp)
		}
		
		/** Remove spaces from the given string. */
		private static function eatSpaces(str:String):String {
			return str.replace(/\s/g, "");
		}
		
		/** Try to lex a number from the string. */
		private static function lexNum():void {
			// numRegex defines a number as an optional number of digits,
			// a possible period, then more digits (at least one). We will match
			// everything thereafter and replace s with it. Negative numbers are
			// lexed as an application of the negate operator.
			
			var res:Object = numRegex.exec(s);
		
			if(res == null)	throw new SyntaxError("expected a number");
		
			// Apropos the false, see the discussion at addImplicitMult.
			addImplicitMult(false);
			pushNewToken(TokenType.NUM, parseFloat(res[1]));
			s = res[2];  // The (.*) section of the regex.
		}
		
		/** Try to lex an identifier from the string. */
		private static function lexId():void {
			// An ID is something that could be a variable, a function name, or
			// a constant. idRegex defines it as beginning with a letter or
			// underscore and continuing with any alphanumerics.
			// There are obviously semantic implications of what type of ID this
			// is found to be (e.g.: a function must be followed by a paren),
			// but that's for the parser to deal with.

			var tok:Token;
			var id:String, newS:String;
			var res:Object = idRegex.exec(s);
			
			if(res == null)	throw new SyntaxError("expected an identifier");
			
			id = res[1];
			newS = res[2]; // The (.*) section of the regex.
			
			tok = idToToken(id);
			
			// If we're not doing implicit multiplication, the whole regexp
			// match is our only option.
			if(tok != null)	{
				addImplicitMult();
				tokens.push(tok);
				s = newS;
				return;
			}
			// Otherwise, keep paring off one letter at time from the right
			// of the id until we hit something we know about.
			else if(env.doImplicitMult && id.length > 1) {
				while(id.length > 1) {
					newS = id.charAt(id.length - 1) + newS;
					id = id.substr(0, id.length - 1);
					
					tok = idToToken(id);
					if(tok != null) {
						addImplicitMult();
						tokens.push(tok);
						s = newS;
						return;
					}
				}
			}
			
			throw new SyntaxError("unknown identifier " + id);
		}
								
		
		/**
		* Look up an ID string in the environment and convert it to the
		* appropriate token type.  Returns null if no match could be found.
		*/
		private static function idToToken(id:String):Token {
			var tok:Token;
			
			if(env.fns[id] != undefined)
				tok = new Token(TokenType.FN, env.fns[id]);
			else if(env.consts[id] != undefined)
				tok = new Token(TokenType.CONST, env.consts[id]);
			else if(env.vars[id] != undefined)
				tok = new Token(TokenType.VAR, env.vars[id]);
			
			return tok;
		}
		
		/**
		* Try to lex a minus sign from the string. This could be a subtraction
		* or a negation--<code>shouldNegate</code> figures that out.
		*/
		private static function lexMinus():void {
			if(s.charAt(0) != "-")
				throw new SyntaxError("expected a minus");
			
			if(shouldNegate()) {
				pushNewToken(TokenType.NEGATE, env.negate);
				s = s.substring(1);
			}
			else {
				pushNewToken(TokenType.ADDOP, env.subtract);
				s = s.substring(1);
			}
		}

		/**
		* Returns true if a minus sign in the string should be treated as a
		* negate rather than a subtraction. This depends on the preceding token:
		*   {empty, "(", op, ",", "^", negate} - *  --> negate
		*   anything else - *                       --> subtract
		*/
		private static function shouldNegate():Boolean {
			var last:Token;

			if(tokens.length == 0)
				return true;

			last = tokens[tokens.length - 1];
			return last.type == TokenType.LP    ||
				   last.type == TokenType.ADDOP ||
				   last.type == TokenType.MULOP ||
				   last.type == TokenType.COMMA ||
				   last.type == TokenType.POW   ||
				   last.type == TokenType.NEGATE;
		}

		/** Try to lex an operator from the string. */
		private static function lexOp():void {
			var c:String = s.charAt(0);
			
			if(env.addops[c] != undefined)
				pushNewToken(TokenType.ADDOP, env.addops[c]);
			else if(env.mulops[c] != undefined)
				pushNewToken(TokenType.MULOP, env.mulops[c]);
			else if(c == "^")
				pushNewToken(TokenType.POW, env.pow);
			else
				throw new SyntaxError("expected an operator");
			
			s = s.substring(1);
		}
		
	}
}
