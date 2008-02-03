package mathlib.grapher {
	import flash.display.Sprite;

	/**
	* A graph of a function of one variable. To create one and add it to a
	* particular Grapher2D, use that object's <code>addFnGraph()</code> method.
	* @see Grapher2D#addFnGraph()
	*/
	public class FnGraph extends Sprite {
		/** The grapher into which this object is drawn. */
		public var parentGrapher:Grapher2D;

		/** The line style to use for the function graph. */
		public var lineStyle:LineStyle = LineStyle.Hairline;

		/** The function to be graphed. */
		public var fn:Function;

		/**
		* Creates a new FnGraph object. End-users should never have reason to
		* call this; instead, use the <code>addFnGraph()</code> method of a 
		* Grapher2D instance.
		* @param _parentGrapher The Grapher2D instance with which this graph
		*  is associated.
		* @param _fn The function to graph. This function must be capable of
		*  being called with one Number argument and must return a Number.
		* @param _lineStyle The line style to use when drawing the graph of the
		*  function. If it is given as <code>null</code>,
		*  <code>LineStyle.Hairline</code> is used.
		* @see Grapher2D#addFnGraph()
		* @see LineStyle#Hairline
		*/
		public function FnGraph(_parentGrapher:Grapher2D, _fn:Function, _lineStyle:LineStyle = null):void {
			super();

			fn = _fn;
			parentGrapher = _parentGrapher;
			
			if(_lineStyle == null) lineStyle = LineStyle.Hairline;
			else lineStyle = _lineStyle;

			// If we don't do this, the double click event won't bubble up to
			// the parent grapher if the user double clicks directly on the
			// graph.
			doubleClickEnabled = true;
		}
		
		/**
		* @private
		* Draw the graph. The function's value is sampled parentGrapher.xres
		* times per on-screen pixel, and the results are connected by a straight
		* line in the given LineStyle.
		*/
		internal function draw():void {
			// parentGrapher.dx is the ratio of real on-screen pixels to a
			// distance of 1 in graph units, so this value is the distance
			// between samples we want to take.
			const xstep:Number = 1 / (parentGrapher.xres * parentGrapher.dx);
			var curx:Number, cury:Number;
			var oldx:Number, oldy:Number;

			lineStyle.apply(graphics);

			// Todo: better handling of discontinuities somehow

			oldx = parentGrapher.xmin;
			oldy = fn(oldx);

			for(curx = parentGrapher.xmin + xstep;
				curx <= parentGrapher.xmax + xstep; // We go one past in case xres is low
				curx += xstep)
			{
				cury = fn(curx);
				
				// If both points are numbers (i.e., not an overflow or NaN),
				// and if the segment would actually be visible in the graph,
				// draw it.
				if(parentGrapher.isDrawableY(oldy) &&
				   parentGrapher.isDrawableY(cury) &&
				   !parentGrapher.isSegmentOutside(cury, oldy))
				{
					// See the comment below about the role of truncateY.
					parentGrapher.graphMoveTo(graphics, oldx, truncateY(oldy));
					parentGrapher.graphLineTo(graphics, curx, truncateY(cury));
				}
				
				oldx = curx;
				oldy = cury;
			}
		}
		
		/**
		* @private
		* Draw the graph, clearing the display first.
		*/
		internal function redraw():void {
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