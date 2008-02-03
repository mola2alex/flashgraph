package mathlib.grapher {
	import flash.display.Graphics;
	
	/**
	* Encapsulates the options to <code>Graphics.lineStyle()</code>. This object
	* is used to specify how to draw the graphs of functions and lines in the
	* FnGraph and PtGraph classes.
	*/
	public class LineStyle {
		public var thickness:Number;
		public var color:uint;
		public var alpha:Number;
		public var pixelHinting:Boolean;
		public var scaleMode:String;
		public var caps:String;
		public var joints:String;
		public var miterLimit:Number;

		/** A solid black hairline. */
		public static const Hairline:LineStyle = new LineStyle(0);

		/** A 1px solid black line. */
		public static const OnePt:LineStyle = new LineStyle(1);
		
		/**
		* Creates a new LineStyle object. The arguments are identical to those
		* to <code>Graphics.lineStyle()</code>, so see there for details.
		*/
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
		
		/**
		* Apply the LineStyle to the given Graphics instance. This makes a call
		* to <code>gr.lineStyle()</code> with the appropriate arguments.
		*/
		public function apply(gr:Graphics):void {
			gr.lineStyle(thickness, color, alpha, pixelHinting, scaleMode, caps, joints, miterLimit);
		}
	}
}