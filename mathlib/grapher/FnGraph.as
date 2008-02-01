package mathlib.grapher {
	import flash.display.Sprite;

	public class FnGraph extends Sprite {
		public var fn:Function, parentGrapher:Grapher2D, lineStyle:LineStyle;

		public function FnGraph(n_parentGrapher:Grapher2D, n_fn:Function, n_lineStyle:LineStyle = null):void {
			super();

			fn = n_fn;
			parentGrapher = n_parentGrapher;
			
			if(n_lineStyle == null) lineStyle = LineStyle.Hairline;
			else lineStyle = n_lineStyle;

			doubleClickEnabled = true;
		}
		
		public function draw():void {
			const xstep:Number = 1 / (parentGrapher.xres * parentGrapher.dx);
			var curx:Number, cury:Number;
			var oldx:Number, oldy:Number;

			lineStyle.apply(graphics);

			// this seems pretty sensible.  maybe implement "pickup" for discontinuities
			// ripe for optimization.  timing test?  necessary?

			oldx = parentGrapher.xmin;
			oldy = fn(oldx);

			for(curx = parentGrapher.xmin + xstep;
				curx <= parentGrapher.xmax + xstep; // we go one past in case xres is low
				curx += xstep)
			{
				cury = fn(curx);
				if(parentGrapher.isDrawableY(oldy) &&
				   parentGrapher.isDrawableY(cury) &&
				   !parentGrapher.isSegmentOutside(cury, oldy))
				{
					parentGrapher.graphMoveTo(graphics, oldx, truncateY(oldy));
					parentGrapher.graphLineTo(graphics, curx, truncateY(cury));
				}
				oldx = curx;
				oldy = cury;
			}
		}
		
		public function redraw():void {
			graphics.clear();
			draw();
		}
		
		// We can hit the 32768 pixel limit on lines really quickly if we have a
		// discontinuity, so we do a heavy-handed (but fast) truncation of y's
		// outside of the viewing window. If xres is high enough, the user
		// shouldn't notice this (it'll just be on the last sample before it
		// jumps out of sight).
		private function truncateY(cury:Number):Number {
			if(cury > parentGrapher.ymax) return parentGrapher.ymax;
			if(cury < parentGrapher.ymin) return parentGrapher.ymin;
			return cury;
		}
	}
}