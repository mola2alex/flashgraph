﻿package mathlib.expr.datatype {

	/**
	* Enumeration class for representing the type of a Token.
	*/
	public class TokenType {
		/** The description of the token as given in the constructor. */
		private var desc:String;

		/**
		* Creates a new instance of a TokenType.
		* @param _desc This is used to print error messages and should be a
		*  short, one or two word description of the type.
		*/
		public function TokenType(_desc:String):void { desc = _desc; }

		/** Returns the description of the TokenType. */
		public function toString():String { return desc; }


		/** Left parenthesis. */
		public static const LP:TokenType = new TokenType("(");
		
		/** Right parenthesis */
		public static const RP:TokenType = new TokenType(")");

		/** Comma. */
		public static const COMMA:TokenType = new TokenType(",");

		/** Addition operator. */
		public static const ADDOP:TokenType = new TokenType("addition operator");

		/** Multiplication operator. */
		public static const MULOP:TokenType = new TokenType("multiplication operator");

		/** Function name. */
		public static const FN:TokenType = new TokenType("function");

		/** Constant name. */
		public static const CONST:TokenType = new TokenType("constant");

		/** Variable name. */
		public static const VAR:TokenType = new TokenType("variable");

		/** Literal number. */
		public static const NUM:TokenType = new TokenType("number");

		/** Prefix negation operator. */
		public static const NEGATE:TokenType = new TokenType("negate");

		/** Exponentiation operator (^). */
		public static const POW:TokenType = new TokenType("exponentiation");
	}
}