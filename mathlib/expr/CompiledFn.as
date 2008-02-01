package mathlib.expr {
	import mathlib.expr.datatype.IndVar;
	
	/**
	* Represents the executable results of a compiled expression. Use the 
	* <code>eval</code> method to substitute values for independent variables
	* and return the Number result.
	*/
	public class CompiledFn {
		/**
		* The array representing a prefix traversal of the ParseTree for the 
		* original expression. This is generated by the Compiler.
		*/
		public var prefixArray:Array;
		
		/** The Environment used in compiling the expression. */
		public var env:Environment;

		/**
		* The index into <code>prefixArray</code> where <code>evalArr</code>
		* picks up.
		*/
		private var cursor:int;
		
		/**
		* Creates a new instance of a CompiledFn.  End-users should never call
		* this; use the methods of Compiler to create CompiledFns.
		* @param _env The Environment used in compiling the expression.
		* @param _prefixArray The array generated by doing a prefix traversal
		*  of the ParseTree for the original expression.
		*/
		public function CompiledFn(_env:Environment, _prefixArray:Array):void {
			env = _env;
			prefixArray = _prefixArray;
		}
		
		/**
		* Evaluates the expression with the given values for the independent
		* variables.
		* @param varVals The Number values to substitute for the independent
		*  variables. These are applied in order of their instantiation in the
		*  Environment. For instance, the call <code>eval(1, 2, 3)</code> on a
		*  CompiledFn with an Environment constructed by the call
		*  <code>Environment("x", "y", "z")</code> would result in
		*  <code>x = 1</code>, <code>y = 2</code>, and <code>z = 3</code>.
		*  Expressions with no independent variables may be evaluated by calling
		*  <code>eval()</code> with no arguments.
		* @throws ArgumentError <code>ArgumentError</code>: Received the wrong
		*  number of arguments.
		*/
		public function eval(... varVals):Number {
			var i:int, argCount:int = varVals.length;
			
			if(env.varCount != argCount)
				throw new ArgumentError("Expected " + env.varCount + " arguments, but got " + argCount); 
			
			for(i = 0; i < argCount; i++)
				env.vars[i].val = varVals[i];
				
			return evalAsIs();
		}
		
		/**
		* Evaluates the expression with the given array of values for the
		* independent variables. This method functions exactly like
		* <code>eval</code> except it takes an array for the variable values
		* rather than a list.
		* @param varVals An array of Number values.
		* @throws ArgumentError <code>ArgumentError</code>: Received the wrong
		*  number of arguments.
		*/
		public function evalWithArray(varVals:Array):Number {
			return eval.apply(this, varVals);
		}
		
		/**
		* @private
		* Evaluates the expression without substituting any values for the
		* indepedent variables. This is used by <code>eval</code> after it
		* sets up the variables, and also by the optimizing compiler to evaluate
		* subtrees of the parse tree that it knows to be constant.
		*/
		internal function evalAsIs():Number {
			cursor = 0;
			return evalArr();
		}
		
		/**
		* This function actually evaluates the prefix array, starting at index
		* <code>cursor</code>.
		*/
		private function evalArr():Number {
			var i:int, arity:int, f:Function, vals:Array, head:*;
			
			if(cursor > prefixArray.length - 1)
				throw new Error("unexpected end of compiled function array");

			head = prefixArray[cursor++];

			// Constants collapse to numbers at lex time
			if(head is Number) return head;
			
			if(head is IndVar) return head.val;

			if(head is Function) {
				// Little known fact: a Function's length is its arity
				f = head;
				arity = f.length;
				
				// Almost all the functions anyone would be using will have 0,
				// 1, or 2 arguments, so we unwind the loop for those cases.
				switch(arity) {
					case 0:
						return f();
		
					case 1:
						return f(evalArr());
		
					case 2:
						return f(evalArr(), evalArr());
		
					default:
						vals = new Array(arity);
		
						for(i = 0; i < arity; i++)
							vals[i] = evalArr();
		
						return f.apply(null, vals);
				}
			}
	
			throw new Error("unexpected element in compiled function array: " + head.toString());
		}
		
	}
}
