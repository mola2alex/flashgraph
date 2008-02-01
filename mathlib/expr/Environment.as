package mathlib.expr {
	import flash.utils.Dictionary;
	import mathlib.expr.datatype.IndVar;
	
	/**
	* Encapsulates the known functions, constants, operators and variables in a
	* particular parse.
	*/
	public class Environment {
		/**
		* Map of function names to Function objects. Members can be added with
		* with the <code>addFn</code> method.
		*/
		public var fns:Dictionary = new Dictionary();
		
		/**
		* Map of constant names to their Number values. Members can be added
		* with the <code>addConst</code> method.
		*/
		public var consts:Dictionary = new Dictionary();
		
		/**
		* Map of strings to binary Functions. These are operators having the
		* same precedence as addition (+, -). Members can be added with the
		* <code>addAddOp</code> method.
		*/
		public var addops:Dictionary = new Dictionary();

		/**
		* Map of strings to binary Functions. These are operators having the
		* same precedence as multiplication (~~, /). Members can be added with
		* the <code>addMulOp</code> method.
		*/
		public var mulops:Dictionary = new Dictionary();
		
		/**
		* Map of strings and integers to IndVars. The contents are indexed
		* by both variable name and their integral index. Members can be added
		* in the constructor or with the <code>addVar</code> and
		* <code>addVars</code> methods.
		*/
		public var vars:Dictionary = new Dictionary();

		/** The number of IndVars in the <code>vars</code> Dictionary. */
		public var varCount:int;

		/** Set to true to allow implicit multiplication (e.g., 5x -> 5~~x). */
		public var doImplicitMult:Boolean = true;
		

		// These are functions that have a special meaning to the lexer.
		/** @private The binary function used for implicit multiplication. */
		internal var implicitMulOp:Function;

		/** @private The unary negate function. */
		internal var negate:Function;
		
		/** @private The subtract function. */
		internal var subtract:Function;
		
		/** @private The exponentiation (^) function. */
		internal var pow:Function;
		
		
		/**
		* Creates a new instance of an Environment. This establishes a large
		* number of default functions, constants and operators.
		* @param ... The constructor may be given no arguments, an array of
		*  Strings, or a list of Strings. In the first case, no independent
		*  variable names are set up. In the latter cases, the given strings 
		*  are passed along to the <code>addVars</code> method.
		*
		* <p>The following functions are present in a default Environment:
		*  <table class="innertable"><th>Function</th><th>Corresponding ActionScript</th><th>Meaning</th>
		*  <tr><td><code>sin(x)</code></td><td><code>Math.sin(x)</code></td><td>The sine of <code>x</code> where <code>x</code> is in radians</td></tr>
		*  <tr><td><code>cos(x)</code></td><td><code>Math.cos(x)</code></td><td>The cosine of <code>x</code> where <code>x</code> is in radians</td></tr>
		*  <tr><td><code>tan(x)</code></td><td><code>Math.tan(x)</code></td><td>The tangent of <code>x</code> where <code>x</code> is in radians</td></tr>
		*  <tr><td><code>asin(x)</code>, <code>arcsin(x)</code></td><td><code>Math.asin(x)</code></td><td>The arcsine of <code>x</code> in radians</td></tr>
		*  <tr><td><code>acos(x)</code>, <code>arccos(x)</code></td><td><code>Math.acos(x)</code></td><td>The arccosine of <code>x</code> in radians</td></tr>
		*  <tr><td><code>atan(x)</code>, <code>arctan(x)</code></td><td><code>Math.atan(x)</code></td><td>The arctangent of <code>x</code> in radians</td></tr>
		*  <tr><td><code>atan2(x, y)</code>, <code>arctan2(x, y)</code></td><td><code>Math.atan2(x, y)</code></td><td>The arctangent of <code>y / x</code> in radians</td></tr>
		*  <tr><td><code>exp(x)</code></td><td><code>Math.exp(x)</code></td><td><code>e^x</code> where <code>e</code> is Euler's constant</td></tr>
		*  <tr><td><code>sqrt(x)</code></td><td><code>Math.sqrt(x)</code></td><td>The square root of <code>x</code></td></tr>
		*  <tr><td><code>pow(x, p)</code></td><td><code>Math.pow(x, p)</code></td><td><code>x^p</code></td></tr>
		*  <tr><td><code>log(x)</code>, <code>ln(x)</code></td><td><code>Math.log(x)</code></td><td>The natural logarithm of <code>x</code></td></tr>
		*  <tr><td><code>log10(x)</code></td><td><code>Math.log(x) / Math.LN10</code></td><td>The base-10 logarithm of <code>x</code></td></tr>
		*  <tr><td><code>log2(x)</code></td><td><code>Math.log(x) / Math.LN2</code></td><td>The base-2 logarithm of <code>x</code></td></tr>
		*  <tr><td><code>max(x, y)</code></td><td><code>Math.max(x, y)</code></td><td>The maximum of <code>x</code> and <code>y</code></td></tr>
		*  <tr><td><code>min(x, y)</code></td><td><code>Math.min(x, y)</code></td><td>The minimum of <code>x</code> and <code>y</code></td></tr>
		*  <tr><td><code>abs(x)</code></td><td><code>Math.abs(x)</code></td><td>The absolute value of <code>x</code></td></tr>
		*  <tr><td><code>floor(x)</code></td><td><code>Math.floor(x)</code></td><td>The closest integer less than or equal to <code>x</code></td></tr>
		*  <tr><td><code>ceil(x)</code></td><td><code>Math.ceil(x)</code></td><td>The closest integer greater than or equal to <code>x</code></td></tr>
		*  <tr><td><code>round(x)</code></td><td><code>Math.round(x)</code></td><td>The closest integer to <code>x</code>. If <code>x</code> ends in .5, it is rounded up.</td></tr>
		*  <tr><td><code>random()</code>, <code>rnd()</code>, <code>rand()</code></td><td><code>Math.random()</code></td><td>A pseudo-random number between 0 and 1</td></tr>
		*  <tr><td><code>mod(x, m)</code></td><td><code>x % m</code></td><td>The remainder when <code>x</code> is divided by <code>m</code></td></tr>
		*  </table></p>
		* <p>The following constants are present in a default Environment:
		*  <table class="innertable"><th>Constant Name</th><th>Corresponding ActionScript</th><th>Meaning</th>
		*  <tr><td><code>e</code></td><td><code>Math.E</code></td><td>Euler's constant, the base of natural logarithms</tr>
		*  <tr><td><code>ln10</code>, <code>log10</code></td><td><code>Math.LN10</code></td><td>The natural logarithm of 10</td></tr>
		*  <tr><td><code>ln2</code>, <code>log2</code></td><td><code>Math.LN2</code></td><td>The natural logarithm of 2</td></tr>
		*  <tr><td><code>log10e</code></td><td><code>Math.LOG10E</code></td><td>The base-10 logarithm of e</td></tr>
		*  <tr><td><code>log2e</code></td><td><code>Math.LOG2E</code></td><td>The base-2 logarithm of e</td></tr>
		*  <tr><td><code>pi</code></td><td><code>Math.PI</code></td><td>The ratio of a circle's circumference to its diameter</td></tr>
		*  <tr><td><code>sqrt1_2</code></td><td><code>Math.SQRT1_2</code></td><td>The square root of one-half</td></tr>
		*  <tr><td><code>sqrt2</code></td><td><code>Math.SQRT2</code></td><td>The square root of 2</td></tr>
		*  </table></p>
		* <p>The following operators are present in a default Environment, with
		*  the same meaning as in ActionScript: <code>+, -, ~~, /<code>.</p>
		*
		* @example The following code results in three equivalent Environments.
		*  <listing>
		*   var env1:Environment = new Environment()
		*   env1.addVars(["x", "y"]);
		*   var env2:Environment = new Environment(["x", "y"]);
		*   var env3:Environment = new Environment("x", "y");</listing>
		*
		* @throws ArgumentError <code>ArgumentError</code>: A variable name is
		*  invalid or conflicts with another identifier.
		*/
		public function Environment(... args):void {
			varCount = 0;
			
			if(args.length == 1 && args[0] is Array)
				addVars(args[0]);
			else if(args.length > 0)
				addVars(args);
				
			// trig	
			fns["sin"] = Math.sin;
			fns["cos"] = Math.cos;
			fns["tan"] = Math.tan;
			fns["asin"] = Math.asin;
			fns["arcsin"] = Math.asin;
			fns["acos"] = Math.acos;
			fns["arccos"] = Math.acos;
			fns["atan"] = Math.atan;
			fns["arctan"] = Math.atan;
			fns["atan2"] = Math.atan2;
			fns["arctan2"] = Math.atan2;
			
			// exponentiation, etc.
			fns["exp"] = Math.exp;
			fns["sqrt"] = Math.sqrt;
			fns["pow"] = Math.pow;
			fns["log"] = Math.log;
			fns["ln"] = Math.log;
			fns["log10"] = log10;
			fns["log2"] = log2;

			// miscellaneous
			fns["max"] = Math.max;
			fns["min"] = Math.min;
			fns["abs"] = Math.abs;
			fns["floor"] = Math.floor;
			fns["ceil"] = Math.ceil;
			fns["round"] = Math.round;
			fns["random"] = Math.random;
			fns["rnd"] = Math.random;
			fns["rand"] = Math.random;
			fns["mod"] = mod;
			
			// operators
			addops["-"] = subtractfn;
			addops["+"] = add;
			mulops["*"] = mult;
			mulops["/"] = div;

			// constants		
			consts["e"] = Math.E;
			consts["ln10"] = Math.LN10;
			consts["log10"] = Math.LN10;
			consts["ln2"] = Math.LN2;
			consts["log2"] = Math.LN2;
			consts["log10e"] = Math.LOG10E;
			consts["log2e"] = Math.LOG2E;
			consts["pi"] = Math.PI;
			consts["sqrt1_2"] = Math.SQRT1_2;
			consts["sqrt2"] = Math.SQRT2;
			
			// important things to the parser & lexer
			subtract = subtractfn;
			negate = negatefn;
			pow = Math.pow;
			implicitMulOp = mult;
		}
		
		/**
		* Add a variable to the given instance.
		* @param varName The new variable name to add. If this is already a
		*  known identifier (i.e., if <code>isKnownId(varName)</code> is true)
		*  or if it is an invalid identifier (i.e.,
		*  <code>isValidId(varName)</code> is false), an 
		* <code>ArgumentError</code> will be thrown.
		* @throws ArgumentError <code>ArgumentError</code>: The variable name is
		*  invalid or conflicts with another identifier.
		*/
		public function addVar(varName:String):void {
			dieIfBadId(varName);
				
			var v:IndVar = new IndVar(varCount);
			vars[varName] = v;
			vars[varCount] = v;
			
			varCount++;
		}
		
		/**
		* Add a number of variables to the given instance.
		* @param varNames An array of Strings corresponding to variable names
		*  to add. They must meet the same requirements as an argument to
		*  <code>addVar</code>.
 		* @throws ArgumentError <code>ArgumentError</code>: A variable name is
		*  invalid or conflicts with another identifier.
		*/
		public function addVars(varNames:Array):void {
			var varName:String;
			
			for each(varName in varNames)
				addVar(varName);
		}
		
		/**
		* Add a function to the given instance.
		* @param fnName The name of the function. If this is already a known
		*  identifier (i.e., if <code>isKnownId(fnName)</code> is true) or if
		*  it is an invalid identifier (i.e., <code>isValidId(fnName)</code> is
		*  false), an <code>ArgumentError</code> will be thrown.
		* @param fn The ActionScript function corresponding to the function 
		*  name. Its arity will be determined from its <code>length</code>
		*  property, so functions that use the <code>...</code> notation for
		*  accepting a variable number of arguments may not work as intended.
 		* @throws ArgumentError <code>ArgumentError</code>: The function name is
		*  invalid or conflicts with another identifier.
		*/
		public function addFn(fnName:String, fn:Function):void {
			dieIfBadId(fnName);
			fns[fnName] = fn;
		}
		
		/**
		* Add a constant to the given instance.
		* @param constName The new constant name to add. If this is already a
		*  known identifier (i.e., if <code>isKnownId(constName)</code> is true)
		*  or if it is an invalid identifier (i.e., 
		*  <code>isValidId(constName)</code> is false), an 
		*  <code>ArgumentError</code> will be thrown.
		* @param constVal The value of the constant.
 		* @throws ArgumentError <code>ArgumentError</code>: The constant name is
		*  invalid or conflicts with another identifier.
		*/
		public function addConst(constName:String, constVal:Number):void {
			dieIfBadId(constName);
			consts[constName] = constVal;
		}

		/**
		* Add an operator with the same precedence as addition to the given
		* instance.
		* @param opName The name of the operator. Little sanity checking is done
		*  on this argument, but it must be a one-character symbol and not a
		*  known identifier (i.e., <code>isKnownId</code> must return false).
		*  If either of these is not the case, an <code>ArgumentError</code>
		*  will be thrown.
		* @param fn The ActionScript function corresponding to the operator 
		*  name. If it is not binary (i.e., if it does not take exactly 2 
		*  arguments), an <code>ArgumentError</code> will be thrown. Its arity 
		*  will be determined from its <code>length</code> property, so
		*  functions that use the <code>...</code> notation for accepting a
		*  variable number of arguments may not work as intended.
 		* @throws ArgumentError <code>ArgumentError</code>: The operator name
		*  conflicts with another identifier or <code>fn</code> is not binary.
		*/		
		public function addAddOp(opName:String, fn:Function):void {
			dieIfBadOp(opName, fn);
			addops[opName] = fn;
		}
		
		/**
		* Add an operator with the same precedence as multiplication to the
		* given instance.
		* @param opName The name of the operator. Little sanity checking is done
		*  on this argument, but it must be a one-character symbol and not a
		*  known identifier (i.e., <code>isKnownId</code> must return false).
		*  If either of these is not the case, an <code>ArgumentError</code>
		*  will be thrown.
		* @param fn The ActionScript function corresponding to the operator 
		*  name. If it is not binary (i.e., if it does not take exactly 2 
		*  arguments), an <code>ArgumentError</code> will be thrown. Its arity 
		*  will be determined from its <code>length</code> property, so
		*  functions that use the <code>...</code> notation for accepting a
		*  variable number of arguments may not work as intended.
 		* @throws ArgumentError <code>ArgumentError</code>: The operator name
		*  conflicts with another identifier or <code>fn</code> is not binary.
		*/
		public function addMulOp(opName:String, fn:Function):void {
			dieIfBadOp(opName, fn);
			mulops[opName] = fn;
		}
		
		/**
		* Returns true if the given string corresponds to a known identifier
		* in this Environment.
		* @param id The identifier to test.
		*/
		public function isKnownId(id:String):Boolean {
			return fns[id]    != undefined ||
			       addops[id] != undefined ||
				   mulops[id] != undefined || 
				   consts[id] != undefined ||
				   vars[id]   != undefined;
		}
			
		/**
		* Returns true if the given string is a valid name for an identifier in
		* this Environment. Note that this does not check for naming conflicts;
		* use <code>isKnownId</code> for that purpose.
		* @param id The identifier to test. A valid identifier begins with a 
		* letter or an underscore and then contains some number of letters,
		* numbers, or underscores.
		*/
		public function isValidId(id:*):Boolean {
			var r:RegExp = /^[A-Za-z_][A-Za-z_0-9]*$/;
			
			return (id is String) && r.test(id);
		}

		/**
		* Throws an appropriate ArgumentError if the given id is invalid or
		* already taken.
		*/
		private function dieIfBadId(id:String):void {
			if(!isValidId(id))
				throw new ArgumentError("invalid variable name: " + id);

			if(isKnownId(id))
				throw new ArgumentError("variable name " + id + " conflicts with another identifier"); 
		}
		
		/**
		* Throws an appropriate ArgumentError if the given operator name is
		* already taken, or if the function does not take 2 arguments.
		*/
		private function dieIfBadOp(opName:String, fn:Function):void {
			if(opName.length != 1)
				throw new ArgumentError("operators must be one character in length");
		
			if(!isKnownId(opName))
				throw new ArgumentError("operator " + opName + " conflicts with another identifier");
			
			if(fn.length != 2)
				throw new ArgumentError("operator functions must take exactly 2 arguments");
		}


		// Function wrappers for operators 
		private function negatefn(x: Number):Number { return -x; }
		private function subtractfn(x:Number, y:Number):Number { return x - y; }
		private function add(x:Number, y:Number):Number { return x + y; }
		private function mult(x:Number, y:Number):Number { return x * y; }
		private function div(x:Number, y:Number):Number { return x / y; }
		private function mod(x:Number, m:Number):Number { return x % m; }
		
		// Implementations of functions that aren't built-in
		private function log10(x:Number):Number { return Math.log(x) / Math.LN10; }
		private function log2(x:Number):Number { return Math.log(x) / Math.LN2; }
	}

}
