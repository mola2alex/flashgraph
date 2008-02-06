package mathlib.expr.datatype {

	/**
	* Simple implementation of an n-ary tree. As its name indicates, its nodes
	* contain Tokens and it is used to represent the results of a parse.
	*/ 
	public class ParseTree {
		/** The token value of this node. */
		public var token:Token;
		
		/** True if the node is a leaf (i.e., it has no children). This is
		* maintained by <code>appendChild()</code> to save frequent checking of
		* <code>children.length</code>.
		* @see #appendChild()
		*/
		public var isLeaf:Boolean;

		/** The children of this node. Its elements are other ParseTrees. */
		public var children:Array;
		
		/**
		* Creates a new instance of a ParseTree.
		* @param _token The Token to be stored in this node.
		* @param _isLeaf If false, the children array will be initialized here,
		*  rather than in the <code>appendChild</code> method.
		*/
		public function ParseTree(_token:Token, _isLeaf:Boolean = true):void {
			token = _token;
			isLeaf = _isLeaf;

			if(!isLeaf)	children = new Array();
		}
		
		/**
		* Add a child to this node by appending it to <code>children</code>.
		* This function also sets <code>isLeaf</code> to false.
		* @param _t The ParseTree that will become the rightmost child.
		* @see #isLeaf
		*/
		public function appendChild(_t:ParseTree):void {
			if(isLeaf) {
				isLeaf = false;
				children = new Array(_t);
			}
			else
				children.push(_t);
		}
		
		/** Converts the tree rooted in this node to a string. */
		public function toString():String {
			var childrenStr:String;
			var i:int;
			
			if(isLeaf)
				return "(" + token.toString() + ")";
			else {
				childrenStr = "(" + token.toString();
				
				for(i = 0; i < children.length; i++)
					childrenStr += children[i].toString();
				
				childrenStr += ")";
				
				return childrenStr;
			}
		}

	}
}