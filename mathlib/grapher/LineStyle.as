﻿package mathlib.grapher {
	import flash.display.Graphics;
	
	public class LineStyle {
		public var thickness:Number;
		public var color:uint;
		public var alpha:Number;
		public var pixelHinting:Boolean;
		public var scaleMode:String;
		public var caps:String;
		public var joints:String;
		public var miterLimit:Number;

		public static const Hairline:LineStyle = new LineStyle(0);
		public static const OnePt:LineStyle = new LineStyle(1);
		
		public function LineStyle(n_thickness:Number, n_color:uint = 0, n_alpha:Number = 1.0, n_pixelHinting:Boolean = false, n_scaleMode:String = "normal", n_caps:String = null, n_joints:String = null, n_miterLimit:Number = 3):void {
			thickness = n_thickness;
			color = n_color;
			alpha = n_alpha;
			pixelHinting = n_pixelHinting;
			scaleMode = n_scaleMode;
			caps = n_caps;
			joints = n_joints;
			miterLimit = n_miterLimit;
		}
		
		public function apply(gr:Graphics):void {
			gr.lineStyle(thickness, color, alpha, pixelHinting, scaleMode, caps, joints, miterLimit);
		}
	}
}