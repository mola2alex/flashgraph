﻿package mathlib.expression.datatype {	public class IndVar {		public var index:int;		public var val:Number;				public function IndVar(_index:int, _val:Number = NaN):void {			if(_index < 0)				throw new ArgumentError("variable indices begin at 0");			index = _index;			val = _val;		}				public function toString():String {			return "[var_" + index.toString() + "]";		}	}}