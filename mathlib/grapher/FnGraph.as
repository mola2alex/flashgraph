package mathlib.grapher {
	import flash.display.Sprite;

	/**
	* A graph of a function of one variable. To create one and add it to a
	* particular Grapher2D, use that object's <code>addFnGraph()</code> method.
	* @see Grapher2D#addFnGraph()
	*/
	public class FnGraph extends Sprite {
		private var _parent:Grapher2D;
		private var _lineStyle:LineStyle;
		private var _fn:Function;

		/**
		* Creates a new FnGraph object. End-users should never have reason to
		* call this; instead, use the <code>addFnGraph()</code> method of a 
		* Grapher2D instance.
		* @param n_parentGrapher The Grapher2D instance with which this graph
		*  is associated.
		* @param n_fn The function to graph. This function must be capable of
		*  being called with one Number argument and must return a Number.
		* @param n_lineStyle The line style to use when drawing the graph of the
		*  function. If it is given as <code>null</code>,
		*  <code>LineStyle.Hairline</code> is used.
		* @see Grapher2D#addFnGraph()
		* @see LineStyle#Hairline
		*/
		public function FnGraph(n_parentGrapher:Grapher2D, n_fn:Function, n_lineStyle:LineStyle = null):void {
			super();

			_fn = n_fn;
			_parent = n_parentGrapher;
			
			if(n_lineStyle == null) _lineStyle = LineStyle.Hairline;
			else _lineStyle = n_lineStyle;

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
			const xstep:Number = 1 / (_parent.xres * _parent.dx);
			var curx:Number, cury:Number;
			var oldx:Number, oldy:Number;

			_lineStyle.apply(graphics);

			// Todo: better handling of discontinuities somehow

			oldx = _parent.xmin;
			oldy = _fn(oldx);

			for(curx = _parent.xmin + xstep;
				curx <= _parent.xmax + xstep; // We go one past in case xres is low
				curx += xstep)
			{
				cury = _fn(curx);
				
				// If both points are numbers (i.e., not an overflow or NaN),
				// and if the segment would actually be visible in the graph,
				// draw it.
				if(_parent.isDrawableY(oldy) &&
				   _parent.isDrawableY(cury) &&
				   !_parent.isSegmentOutside(cury, oldy))
				{
					// See the comment below about the role of truncateY.
					_parent.graphMoveTo(graphics, oldx, truncateY(oldy));
					_parent.graphLineTo(graphics, curx, truncateY(cury));
				}
				
				oldx = curx;
				oldy = cury;
			}
		}
		
		/** Redraw the graph. */
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
			if(cury > _parent.ymax) return _parent.ymax;
			if(cury < _parent.ymin) return _parent.ymin;
			return cury;
		}


		/** The grapher into which this object is drawn. */
		public function get parentGrapher():Grapher2D { return _parent; }
		
		/** The line style to use for the function graph. */
		public function get lineStyle():LineStyle { return _lineStyle; }
		/** @private */
		public function set lineStyle(n_lineStyle:LineStyle):void {
			_lineStyle = n_lineStyle;
			redraw();
		}
		
		/** The function to be graphed. */
		public function get fn():Function { return _fn; }
		/** @private */
		public function set fn(n_fn:Function):void {
			_fn = n_fn;
			redraw();
		}
	}
}