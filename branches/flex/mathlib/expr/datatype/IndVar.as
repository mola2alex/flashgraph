package mathlib.expr.datatype {

	/** Representation of an independent variable used in Tokens. */

	/*
	* An instance of this class is created for each variable in an Environment.
	* Later, each token of type <code>VAR</code> contains a reference to one of
	* those IndVars. Variable substitution is done in the CompiledFn class'
	* <code>eval</code> method by changing the <code>val</code> member of those
	* instances. Lookups in <code>eval</code> are done by <code>index</code>,
	* not name, so instances of this class have no notion of their string name.
	*/
	public class IndVar {
		/** The numeric index of the variable, starting at 0. */
		/*
		* In a call to the <code>eval</code> method of a CompiledFn
		* instance, values are associated with variables in order of this index.
		* For instance, <code>cFn.eval(4, 22)</code> sets the value of the
		* variable with index 0 to 4, and the variable with index 1 to 22.
		*/
		public var index:int;
		
		/**
		* The value of the variable. This is generally unset and unused until
		* a call to the <code>eval</code> method of a CompiledFn instance.
		*/
		public var val:Number;
		
		/**
		* Creates a new IndVar instance.
		* @param _index The index of the new variable (0 or greater).
		* @param _val The default value of the variable.
		*/
		public function IndVar(_index:int, _val:Number = NaN):void {
			if(_index < 0)
				throw new ArgumentError("variable indices begin at 0");

			index = _index;
			val = _val;
		}
		
		/** Returns a string with the index of variable. */
		public function toString():String {
			return "[var_" + index.toString() + "]";
		}
	}
}