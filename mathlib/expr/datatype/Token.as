package mathlib.expr.datatype {

	/** Represents a token from the lexer or parser. */
	public class Token {
		/** The type of token. */
		public var type:TokenType;
		
		/**
		* The (possibly unset) value of the token. The meaning of this field
		* depends on the type. The tokens for left parenthesis, right
		* parenthesis, comma, negate and exponentiation do not hold extra data.
		* @see TokenType
		*/
		public var val:*;
		
		/**
		* Creates a new Token instance.
		* @param _type The type of the token.
		* @param _val Token-specific extra data. For example, Tokens of type
		*  <code>NUM</code> contain the Number value of the token.
		*/
		public function Token(_type:TokenType, _val:* = undefined):void {
			type = _type;
			val = _val;
		}
		
		/**
		* Converts the token to a string including its type and, if set, its
		* value.
		*/
		public function toString():String {
			var desc:String = "[" + type.toString();
			if(val != undefined) desc += ":" + val.toString();
			return desc += "]";
		}
	}
}