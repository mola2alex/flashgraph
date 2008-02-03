package mathlib.grapher {
	import flash.display.Sprite;
	import flash.geom.Point;
	
	/**
	* A graph of a series of points. To create one and add it to a particular
	* Grapher2D, use that object's <code>addPtGraph()</code> method.
	* @see Grapher2D#addPtGraph()
	*/
	public class PtGraph extends Sprite {
		/** The grapher into which this object is drawn. */
		public var parentGrapher:Grapher2D;
		
		/**
		* The style of line to use for drawing connecting lines if
		* <code>connected</code> is true and for the points if
		* <code>showPoints</code> is true.
		*/
		public var lineStyle:LineStyle;

		/** The array of <code>flash.geom.Point</code>s to be drawn. */
		public var pts:Array;
		
		/** True if the points should be draw with lines connecting them. */
		public var connected:Boolean;
		
		/**	True if small circles should be drawn for each point. */
		public var showPoints:Boolean;
		
		/**
		* Create a new PtGraph object. There should never be a reason to call
		* this; instead, use the <code>addPtGraph()</code> method of an instance
		* of Grapher2D. 
		* @param _parentGrapher The Grapher2D instance with which this graph is
		*  associated.
		* @param _pts An array of <code>flash.geom.Point</code>s to be drawn.
		* @param _connected True to draw lines connecting the points in order of
		*  their appearance in <code>_pts</code>
		* @param _showPoints True to draw a small circle at the location of each
		*  point. Note: if <code>connected</code> and this property are both
		*  false, there will be nothing to draw.
		* @param _lineStyle The style of line to use for drawing connecting
		*  lines if <code>connected</code> is true and for points if
		*  <code>showPoints</code> is true. If its value is <code>null</code>,
		*  <code>LineStyle.Hairline</code> is used.
		* @see Grapher2D#addPtGraph()
		* @see LineStyle#Hairline
		*/
		public function PtGraph(_parentGrapher:Grapher2D, _pts:Array, _connected:Boolean = true, _showPoints:Boolean = true, _lineStyle:LineStyle = null):void {
			super();
			
			parentGrapher = _parentGrapher;
			pts = _pts;
			connected = _connected;
			showPoints = _showPoints;
			
			if(_lineStyle == null) lineStyle = LineStyle.Hairline;
			else lineStyle = _lineStyle;

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
			pts.push(new Point(graphx, graphy));
			redraw();
		}
		
		/**
		* @private
		* Draw the graph.
		*/
		internal function draw():void {
			var i:int, pt:Point;
			
			lineStyle.apply(graphics);
			
			for(i = 0; i < pts.length; i++) {
				pt = pts[i];
				
				// Only draw the point if it's inside the current view.
				if(!parentGrapher.isOutside(pt) && showPoints) {
					parentGrapher.graphDrawPoint(graphics, pt.x, pt.y);
				}
				
				// If we're connected we have to draw the line no matter what,
				// since it may cross the view even if both points are outside.
				if(connected && i > 0) {
					var ppt:Point = pts[i - 1];

					parentGrapher.graphMoveTo(graphics, ppt.x, ppt.y);
					parentGrapher.graphLineTo(graphics, pt.x, pt.y);
				}
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
	}
}