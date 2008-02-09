package mathlib.grapher {
	import flash.display.Sprite;
	import flash.geom.Point;
	
	/**
	* A graph of a series of points. To create one and add it to a particular
	* Grapher2D, use that object's <code>addPtGraph()</code> method.
	* @see Grapher2D#addPtGraph()
	*/
	public class PtGraph extends Sprite {
		private var _parent:Grapher2D;
		private var _lineStyle:LineStyle;
		private var _pts:Array;
		private var _connected:Boolean;
		private var _showPoints:Boolean;
		
		/**
		* Create a new PtGraph object. There should never be a reason to call
		* this; instead, use the <code>addPtGraph()</code> method of an instance
		* of Grapher2D. 
		* @param n_parentGrapher The Grapher2D instance with which this graph is
		*  associated.
		* @param n_pts An array of <code>flash.geom.Point</code>s to be drawn.
		* @param n_connected True to draw lines connecting the points in order
		*  of their appearance in <code>_pts</code>
		* @param n_showPoints True to draw a small circle at the location of
		*  each point. Note: if <code>connected</code> and this property are
		*  both false, there will be nothing to draw.
		* @param n_lineStyle The style of line to use for drawing connecting
		*  lines if <code>connected</code> is true and for points if
		*  <code>showPoints</code> is true. If its value is <code>null</code>,
		*  <code>LineStyle.Hairline</code> is used.
		* @see Grapher2D#addPtGraph()
		* @see LineStyle#Hairline
		*/
		public function PtGraph(n_parentGrapher:Grapher2D, n_pts:Array, n_connected:Boolean = true, n_showPoints:Boolean = true, n_lineStyle:LineStyle = null):void {
			super();
			
			_parent = n_parentGrapher;
			_pts = n_pts;
			_connected = n_connected;
			_showPoints = n_showPoints;
			
			if(n_lineStyle == null) lineStyle = LineStyle.Hairline;
			else lineStyle = n_lineStyle;

			// If we don't do this, the double click event won't bubble up to
			// the parent grapher if the user double clicks directly on the
			// graph.			
			doubleClickEnabled = true;
		}

		/**
		* Add a new point to the end of the list and redraw the graph.
		* @param graphx The x-coordinate of the point to add.
		* @param graphy The y-coordinate of the point to add.
		*/
		public function addPoint(graphx:Number, graphy:Number):void {
			_pts.push(new Point(graphx, graphy));
			redraw();
		}
		
		/**
		* @private
		* Draw the graph.
		*/
		internal function draw():void {
			var i:int, pt:Point;
			
			_lineStyle.apply(graphics);
			
			for(i = 0; i < _pts.length; i++) {
				pt = _pts[i];
				
				// Only draw the point if it's inside the current view.
				if(!_parent.isOutside(pt) && _showPoints) {
					_parent.graphDrawPoint(graphics, pt.x, pt.y);
				}
				
				// If we're connected we have to draw the line no matter what,
				// since it may cross the view even if both points are outside.
				if(connected && i > 0) {
					var ppt:Point = _pts[i - 1];

					_parent.graphMoveTo(graphics, ppt.x, ppt.y);
					_parent.graphLineTo(graphics, pt.x, pt.y);
				}
			}
		}
		
		/**
		* Redraw the graph.
		*/
		public function redraw():void {
			graphics.clear();
			draw();
		}


		/** The grapher into which this object is drawn. */
		public function get parentGrapher():Grapher2D { return _parent; }
		
		/**
		* The style of line to use for drawing connecting lines if
		* <code>connected</code> is true and for the points if
		* <code>showPoints</code> is true.
		*/
		public function get lineStyle():LineStyle { return _lineStyle; }
		/** @private */
		public function set lineStyle(n_lineStyle:LineStyle):void {
			_lineStyle = n_lineStyle;
			redraw();
		}
		
		/**
		* The array of <code>flash.geom.Point</code>s to be drawn. If you
		* modify elements of this array you should call <code>redraw()</code> to
		* update the display. If you assign to the property, the redraw will be
		* handled automatically.
		*/
		public function get pts():Array { return _pts; }
		/** @private */
		public function set pts(n_pts:Array):void {
			_pts = n_pts;
			redraw();
		}
		
		/** True if the points should be draw with lines connecting them. */
		public function get connected():Boolean { return _connected; }
		/** @private */
		public function set connected(n_connected:Boolean):void {
			_connected = n_connected;
			redraw();
		}

		/**	True if small circles should be drawn for each point. */
		public function get showPoints():Boolean { return _showPoints; }
		public function set showPoints(n_showPoints:Boolean):void {
			_showPoints = n_showPoints;
			redraw();
		}
	}
}