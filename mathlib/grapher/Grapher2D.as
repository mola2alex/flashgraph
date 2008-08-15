package mathlib.grapher {
	import fl.core.UIComponent;
	import flash.display.*;
	import flash.geom.Point;
	import fl.events.ComponentEvent;
	import fl.managers.IFocusManagerComponent;
	
	/**
	* The Grapher2D component presents a Cartesian plane and graphs thereon.
	* The <code>addFnGraph()</code> and <code>addPtGraph()</code> methods can be
	* used to add persistent graphs of functions and points that update with
	* changes of the graph's viewing window.
	*/
	public class Grapher2D extends UIComponent implements IFocusManagerComponent {
		private var _axesSh:Shape, _borderSh:Shape, _graphSp:Sprite, _maskSh:Shape, _hitArea:Sprite;
		private var _dx:Number, _dy:Number;
		private var _xmin:Number = -10, _xmax:Number = 10, _ymin:Number = -10, _ymax:Number = 10;
		private var _showBorder:Boolean = true, _borderThickness:uint = 1, _borderColor:uint = 0;
		private var _showAxes:Boolean = true, _axesThickness:uint = 1, _axesColor:uint = 0x990000;
		private var _tickStyle:String = TICKSTYLE_TICKMARKS, _tickDx:Number = 1, _tickDy:Number = 1;
		
		private static const MAXTICKSIZE:uint = 5, MINTICKSTEP:uint = 2, GRIDTICKSALPHA:Number = 0.1;
		private static const INV_RANGE:String = "range", INV_CREATE:String = "create", INV_SIZE:String = "size";

		/**
		* The absolute minimum x- and y-range. This is an arbitrary limit
		* obtained by experimentation&#x2014;in theory there should be no limit,
		* but if we step too low, Flash starts to have serious issues with the
		* sort of numbers we'd have to deal with (it slows down and eventually
		* hangs). The methods for adjusting the view and zooming check this
		* value and throw a <code>RangeError</code> if a change would go below
		* this value. The whole situation is unfortunate but unavoidable for the
		* time being.
		* @see #zoom()
		* @see #setRange()
		*/
		public static const ABS_MIN_RANGE:Number = 1e-12; //1e-14;

		/**
		* Set this as the value of <code>tickStyle</code> to turn off tickmarks.
		* @see #tickStyle
		*/
		public static const TICKSTYLE_NONE:String = "none";

		/**
		* Set this as the value of <code>tickStyle</code> to generate small
		* tickmarks from the axes.
		* @see #tickStyle
		*/
		public static const TICKSTYLE_TICKMARKS:String = "tickmarks";
		
		/**
		* Set this as the value of <code>tickStyle</code> to generate a full-
		* frame grid spaced as tickmarks.
		* @see #tickStyle
		*/
		public static const TICKSTYLE_GRID:String = "grid";



		///// Initialization Methods

		/** Creates a new Grapher2D component instance. */
		public function Grapher2D() {
			super();
			
			_borderSh = new Shape();
			_axesSh = new Shape();
			_maskSh = new Shape();
			_graphSp = new Sprite();
			_hitArea = new Sprite();

			// Layering: axes under graphs under border
			addChild(_graphSp);
			addChild(_axesSh);
			addChild(_borderSh);
			
			doubleClickEnabled = true;
			_graphSp.doubleClickEnabled = true;
			
			// We place a mask on the graph sprite to cover up lines that may
			// extend outside of it. The mask won't be displayed, but needs to
			// be in the display list anyway, quoth the the help.
			addChild(_maskSh);
			_graphSp.mask = _maskSh;

			// We also need to make a hit area for our whole graph since we're
			// technically transparent. Like the mask, this sprite needs to be
			// in the display list (though that's not mentioned in the help).
			_hitArea.mouseEnabled = false;
			addChild(_hitArea);
			hitArea = _hitArea;
			
			// This causes a draw() to be called when appropriate.
			invalidate(INV_CREATE);
		}
		
		/**
		* @private
		* Draws the grapher. This is an override of the method in UIComponent.
		*/
		protected override function draw():void	{
			updateDxy();
			drawHitArea();
			drawMask();
			drawBorder();
			drawAxesAndTicks();
			drawGraphs();
		}
		
		// Draw the hit area, a black rectangle the size of the component.
		private function drawHitArea():void {
			var hitGr:Graphics = _hitArea.graphics;
			
			hitGr.clear();			
			hitGr.beginFill(0, 0);
			hitGr.drawRect(0, 0, width, height);
			hitGr.endFill();
		}

		// Draw the graph mask, a white rectangle the size of the component.
		private function drawMask():void {
			var maskGr:Graphics = _maskSh.graphics;
			
			maskGr.clear();
			maskGr.beginFill(0xFFFFFF);
			maskGr.drawRect(0, 0, width, height);
			maskGr.endFill();
		}
		
		// Draw the axes and tickmarks.
		private function drawAxesAndTicks():void {
			var origin:Number, axesGr:Graphics = _axesSh.graphics;
			var tstep:Number, i:Number;
			
			axesGr.clear();
			axesGr.lineStyle(_axesThickness, _axesColor);
			
			if(_showAxes) {
				// x-axis
				if(_ymin <= 0 && _ymax >= 0) {
					origin = graphYToLocalY(0);
					axesGr.moveTo(0, origin);
					axesGr.lineTo(width, origin);
				}
				
				// y-axis
				if(_xmin <= 0 && _xmax >= 0) {
					origin = graphXToLocalX(0);
					axesGr.moveTo(origin, 0);
					axesGr.lineTo(origin, height);
				}
			}
			
			drawTicksInto(axesGr);
		}
		
		// Draw the tickmarks into the given Graphics instance.
		private function drawTicksInto(gr:Graphics):void {
			var i:Number, xorigin:Number, yorigin:Number;
			// physical (pixel) distance between adjacent tickmarks:
			var txstep:Number = _tickDx * _dx, tystep:Number = _tickDy * _dy;
			var firstXTick:Number = _tickDx * Math.ceil(_xmin / _tickDx);
			var firstYTick:Number = _tickDy * Math.ceil(_ymin / _tickDy);
		
			if(_tickStyle == TICKSTYLE_TICKMARKS) {
				// Select the tick size automatically to be no greater than
				// MAXTICKSIZE, but also not bigger than the distance between
				// tickmarks.
				var tickSize:int = Math.min(txstep, tystep, MAXTICKSIZE);
			
				xorigin = graphXToLocalX(0);
				yorigin = graphYToLocalY(0);
				
				// x-axis tickmarks (i.e., perpendicular to the x-axis)
				if(_ymin <= 0 && _ymax >= 0 && txstep > MINTICKSTEP) {
					for(i = firstXTick; i <= _xmax; i += _tickDx) {
						graphMoveTo(gr, i, 0);
						gr.lineTo(graphXToLocalX(i), yorigin - tickSize);
					}
				}
				
				// y-axis tickmarks (i.e., perpendicular to the y-axis)
				if(_xmin <= 0 && _xmax >= 0 && tystep > MINTICKSTEP) {
					for(i = firstYTick; i <= _ymax; i += _tickDy) {
						graphMoveTo(gr, 0, i);
						gr.lineTo(xorigin + tickSize, graphYToLocalY(i));
					}
				}
			}
			
			else if(_tickStyle == TICKSTYLE_GRID) {
				gr.lineStyle(_axesThickness, _axesColor, GRIDTICKSALPHA);

				// vertical grid
				if(txstep > MINTICKSTEP) {
					for(i = firstXTick; i <= _xmax; i += _tickDx) {
						graphMoveTo(gr, i, _ymax);
						graphLineTo(gr, i, _ymin);
					}
				}

				// horizontal grid
				if(tystep > MINTICKSTEP) {										
					for(i = firstYTick; i <= _ymax; i += _tickDy) {
						graphMoveTo(gr, _xmin, i);
						graphLineTo(gr, _xmax, i);
					}
				}
			}
		}
			
		// Draw the border in the user-provided color and thickness.
		private function drawBorder():void {
			var borderGr:Graphics = _borderSh.graphics;
			
			borderGr.clear();
			
			if(_showBorder) {
				borderGr.lineStyle(_borderThickness, _borderColor, 1, true, LineScaleMode.NONE, CapsStyle.NONE, JointStyle.MITER);
				borderGr.drawRect(0, 0, width, height);
			}
		}
	
		// Update all the child graphs.
		private function drawGraphs():void {
			var i:int, child:*;
			
			for(i = 0; i < _graphSp.numChildren; i++) {
				child = _graphSp.getChildAt(i);
				child.redraw();
				// Todo: try {...} that call and handle it better if there's no
				// redraw() method.
			}
		}



		///// Helpers for Graph Classes
		
		/** @private 
		* Move to the given graph coordinate in the given Graphics instance.
		*/
		internal function graphMoveTo(gr:Graphics, graphx:Number, graphy:Number):void {
			gr.moveTo(graphXToLocalX(graphx), graphYToLocalY(graphy));
		}
		
		/** @private
		* Draw a line from the current position to the given graph coordinate in
		* the given Graphics instance.
		*/
		internal function graphLineTo(gr:Graphics, graphx:Number, graphy:Number):void {
			gr.lineTo(graphXToLocalX(graphx), graphYToLocalY(graphy));
		}
		
		/** @private
		* Draw a small circle at the given graph coordinate
		*/
		internal function graphDrawPoint(gr:Graphics, graphx:Number, graphy:Number):void {
			gr.drawCircle(graphXToLocalX(graphx), graphYToLocalY(graphy), 2);
		}
		
		/**
		* Returns true if the given point is outside the viewable range of the
		* grapher.
		* @param pt The point to test.
		*/
		public function isOutside(pt:Point):Boolean {
            return pt.x > _xmax || pt.x < _xmin ||
                   pt.y > _ymax || pt.y < _ymin;
        }
		
		/** @private
		* Assuming the x-coordinates are within the grapher's range, return true
		* if the resulting line segment would be outside the graph.
		*/
		internal function isSegmentOutside(cury:Number, oldy:Number):Boolean {
			return (cury > _ymax && oldy > _ymax) ||
				   (cury < _ymin && oldy < _ymin);
		}
		
		/** @private
		* Returns true if the given value represents a y-coordinate that is 
		* drawable (i.e., not an overflow or NaN).
		*/
		internal function isDrawableY(graphy:Number):Boolean {
			return !isNaN(graphy) && isFinite(graphy);
		}
		
		// Update the _dx and _dy values.
		private function updateDxy():void {
			_dx = width / (_xmax - _xmin);
			_dy = height / (_ymax - _ymin);
		}



		///// Public Helper Methods
		
		/**
		* Remove a graph added by <code>addPtGraph()</code> or
		* <code>addFnGraph()</code>.
		* @param graph The graph to remove. This should be a value returned by
		*  <code>addFnGraph()</code> or <code>addPtGraph()</code>.
		*/
		public function removeGraph(graph:DisplayObject):DisplayObject {
			return _graphSp.removeChild(graph);
		}
		
		/**
		* Add the graph of a function to this grapher. The quality of the graph
		* can be controlled to an extent by the value of <code>xres</code>.
		* @param fn The function to graph. This function must be capable of
		*  being called with one Number argument and must return a Number.
		* @param lineStyle The line style to use when drawing the graph of the
		*  function. If it is given as <code>null</code>,
		*  <code>LineStyle.Hairline</code> is used.
		* @param xres The desired resolution of the function graph. See
		*  the constructor for <code>FnGraph</code> for details.
		* @see LineStyle#Hairline
		* @see FnGraph#FnGraph()
		*/
		public function addFnGraph(fn:Function, lineStyle:LineStyle = null, xres:Number = 1):FnGraph {
			var fg:FnGraph = new FnGraph(this, fn, lineStyle, xres);
			_graphSp.addChild(fg);
			fg.draw();
			
			return fg;
		}
		
		/**
		* Add the graph of a set of points to this grapher.
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
		* @throws RangeError <code>RangeError</code>: the given value for
		*  <code>xres</code> is less than or equal to zero.
		* @see LineStyle#Hairline
		*/
		public function addPtGraph(pts:Array, connected:Boolean = true, showPoints:Boolean = true, lineStyle:LineStyle = null):PtGraph {
			var pg:PtGraph = new PtGraph(this, pts, connected, showPoints, lineStyle);
			_graphSp.addChild(pg);
			pg.draw();
			
			return pg;
		}
		
		/**
		* Zoom the graph window by the specified factor, centering about the
		* given graph coordinate.
		* @param factor The factor by which the range of the graph will be
		*  multiplied. For example, a value of 0.5 will result in the total
		*  visible range of the graph being halved--zooming in by a factor of 2.
		*  If this is confusing, you may prefer the <code>zoomIn()</code> and
		*  <code>zoomOut()</code> functions.
		* @param graphx The x-coordinate of the new center of the graph after
		*  the zoom. If it is NaN, the x-coordinate of the center of the graph
		*  will be used.
		* @param graphy The y-coordinate of the new center of the graph after
		*  the zoom. If it is NaN, the x-coordinate of the center of the graph
		*  will be used.
		* @param zoomTicks If true, the <code>tickDx</code> and
		*  <code>tickDy</code> properties will also be multiplied by
		*  <code>factor</code>, resulting in the ticks remaining an absolute
		*  (on-screen pixel) distance apart.
		* @throws ArgumentError <code>ArgumentError</code>: The given factor is
		*  less than or equal to 0.
		* @throws RangeError <code>RangeError</code>: The zooming would result
		*  in the range of the graph falling below the minimum.
		* @see #zoomOut()
		* @see #zoomIn()
		* @see #ABS_MIN_RANGE
		*/
		public function zoom(factor:Number, graphx:Number = NaN, graphy:Number = NaN, zoomTicks:Boolean = true):void {
			if(factor <= 0) throw new ArgumentError("zoom factor must be > 0");
				
			var xdiff:Number = Math.abs(_xmax - _xmin) * factor / 2;
			var ydiff:Number = Math.abs(_ymax - _ymin) * factor / 2;
			
			// if a center point isn't specified, use the center of the graph
			if(isNaN(graphx)) graphx = localXToGraphX(width / 2);
			if(isNaN(graphy)) graphy = localYToGraphY(height / 2);
			

			setRange(graphx - xdiff, graphx + xdiff, graphy - ydiff, graphy + ydiff, false);
			if(zoomTicks) {
				_tickDx *= factor;
				_tickDy *= factor;
			}

			invalidate(INV_RANGE);
		}
		
		/**
		* Zoom in on the graph by the given factor. This is just a wrapper for
		* <listing>zoom(1 / factor, graphx, graphy, zoomTicks)</listing>
		* @see #zoom()
		*/
		public function zoomIn(factor:Number, graphx:Number = NaN, graphy:Number = NaN, zoomTicks:Boolean = true):void {
			zoom(1 / factor, graphx, graphy, zoomTicks);
		}
		
		/**
		* Zoom out on the graph by the given factor. This is just an alias of
		* the <code>zoom()</code> method for convenience.
		* @see #zoom()
		*/
		public function zoomOut(factor:Number, graphx:Number = NaN, graphy:Number = NaN, zoomTicks:Boolean = true):void {
			zoom(factor, graphx, graphy, zoomTicks);
		}
		
		/**
		* Center the graph about the given graph coordinate. This is just a
		* wrapper for
		* <listing>zoom(1, graphx, graphy)</listing>
		* @see #zoom()
		*/
		public function centerAbout(graphx:Number, graphy:Number):void {
			zoom(1, graphx, graphy);
		}



		///// Point conversion functions

		/**
		* Convert the given graph x-coordinate to an x-coordinate local to the
		* grapher instance.
		*/
		public function graphXToLocalX(graphx:Number):Number {
			return _dx * (graphx - _xmin);
		}
		
		/**
		* Convert the given graph y-coordinate to a y-coordinate local to the
		* grapher instance.
		*/
		public function graphYToLocalY(graphy:Number):Number {
			return _dy * (_ymax - graphy);
		}
		
		/** Convert the given graph point to a point local to the grapher. */
		public function graphToLocal(graphpt:Point):Point {
			return new Point(graphXToLocalX(graphpt.x), graphYToLocalY(graphpt.y));
		}
		
		/**
		* Convert the given grapher-local x-coordinate to an x-coordinate in the
		* grapher's viewable region.
		*/
		public function localXToGraphX(localx:Number):Number {
			return _xmin + localx / _dx;
		}
		
		/**
		* Convert the given grapher-local y-coordinate to a y-coordinate in the 
		* grapher's viewable region.
		*/
		public function localYToGraphY(localy:Number):Number {
			return _ymax - localy / _dy;
		}
		
		/**
		* Convert the given grapher-local point to a point in graph coordinates.
		*/
		public function localToGraph(localpt:Point):Point {
			return new Point(localXToGraphX(localpt.x), localXToGraphX(localpt.y));
		}
		
		/**
		* Convert the given point in global coordinates to one in graph
		* coordinates.
		*/
		public function globalToGraph(globalpt:Point):Point {
			return localToGraph(globalToLocal(globalpt));
		}
		
		/**
		* Convert the given point in graph coordinates to one in global
		* coordinates.
		*/
		public function graphToGlobal(graphpt:Point):Point {
			return localToGlobal(graphToLocal(graphpt));
		}
		

		
		///// Getters & Setters

		/**
		* Set the x-range of the grapher. Use this function instead of setting
		* the <code>xmin</code> and <code>xmax</code> properties if you are
		* changing both simultaneously and would like to avoid an intermediate
		* redraw.
		* @param n_xmin The new value of <code>xmin</code>.
		* @param n_xmax The new value of <code>xmax</code>.
		* @param doRedraw If true, redraw the graph after this change.
		* @throws RangeError <code>RangeError</code>: Either
		*  <code>n_xmin >= n_xmax</code> or the values would result in the graph
		*  having a range below the minimum.
		* @see #xmin
		* @see #xmax
		* @see #ABS_MIN_RANGE
		*/
		public function setXRange(n_xmin:Number, n_xmax:Number, doRedraw:Boolean = true):void {
			if(n_xmin >= n_xmax)
				throw new RangeError("xmin must be strictly less than xmax");
			if(Math.abs(n_xmax - n_xmin) <= ABS_MIN_RANGE)
				throw new RangeError("range too small");

			_xmin = n_xmin;
			_xmax = n_xmax;
			if(doRedraw) invalidate(INV_RANGE);
		}
		
		/**
		* Set the y-range of the grapher. Use this function instead of setting
		* the <code>ymin</code> and <code>ymax</code> properties if you are
		* changing both simultaneously and would like to avoid an intermediate
		* redraw.
		* @param n_ymin The new value of <code>ymin</code>.
		* @param n_ymax The new value of <code>ymax</code>.
		* @param doRedraw If true, redraw the graph after this change.
		* @throws RangeError <code>RangeError</code>: Either
		*  <code>n_ymin >= n_ymax</code> or the values would result in the graph
		*  having a range below the minimum.
		* @see #ymin
		* @see #ymax
		* @see #ABS_MIN_RANGE
		*/
		public function setYRange(n_ymin:Number, n_ymax:Number, doRedraw:Boolean = true):void {
			if(n_ymin >= n_ymax)
				throw new RangeError("ymin must be strictly less than ymax");
			if(Math.abs(n_ymax - n_ymin) <= ABS_MIN_RANGE)
				throw new RangeError("range too small");

			_ymin = n_ymin;
			_ymax = n_ymax;
			if(doRedraw) invalidate(INV_RANGE);
		}
		
		/**
		* Set the range of the grapher. Use this function instead of setting
		* the range properties if you are changing many at once and would like
		* to avoid intermediate redraws.
		* @param n_xmin The new value of <code>xmin</code>.
		* @param n_xmax The new value of <code>xmax</code>.
		* @param n_ymin The new value of <code>ymin</code>.
		* @param n_ymax The new value of <code>ymax</code>.
		* @doRedraw If true, redraw the graph after this change.
		* @throws RangeError <code>RangeError</code>: Either one of the
		*  <code>min</code>s is greater than or equal to its respective
		*  <code>max</code> or the values would result in the graph having a
		*  range below the minimum.
		* @see #xmin
		* @see #xmax
		* @see #ymin
		* @see #ymax
		* @see #ABS_MIN_RANGE
		*/
		public function setRange(n_xmin:Number, n_xmax:Number, n_ymin:Number, n_ymax:Number, doRedraw:Boolean = true):void {
			setXRange(n_xmin, n_xmax, false);
			setYRange(n_ymin, n_ymax, doRedraw);
		}
		
		/**
		* Set the distance between ticks on the x- and y-axes. Use this function
		* instead of setting the <code>tickDx</code> and <code>tickDy</code>
		* properties if you are changing both at once and would like to avoid
		* an intermediate redraw.
		* @param n_tickDx The new value of <code>tickDx</code>.
		* @param n_tickDy The new value of <code>tickDy</code>.
		* @param doRedraw If true, redraw the graph after this change.
		* @throws RangeError <code>RangeError</code>: One of the new tick
		*  spacing values is <= 0.
		* @see #tickDx
		* @see #tickDy
		*/
		public function setTickDxy(n_tickDx:Number, n_tickDy:Number, doRedraw:Boolean = true):void {
			if(n_tickDx <= 0 || n_tickDy <= 0)
				throw new RangeError("tick spacings must be > 0");

			_tickDx = n_tickDx;
			_tickDy = n_tickDy;
			if(doRedraw) drawAxesAndTicks();
		}
		
		/**
		* The ratio of the grapher's width to its x-range. Put another way, this
		* is the number of physical pixels per a horizontal distance of 1 in the
		* graph. For example, if the grapher is 100 pixels wide,
		* <code>xmin = -10</code> and <code>xmax = 10</code>, then
		* the value of <code>dx</code> will be 5.
		*/
		public function get dx():Number { return _dx; }
		
		/**
		* The ratio of the grapher's height to its y-range. See <code>dx</code>
		* for further explanation.
		* @see #dx
		*/
		public function get dy():Number { return _dy; }
		
		[Bindable]
		[Inspectable(defaultValue = -10)]
		/**
		* The minimum x-value to show in the graph.
		* @default -10
		* @throws RangeError <code>RangeError</code>: either the value is
		*  greater than or equal to <code>xmax</code> or the resulting range
		*  would be less than the minimum.
		* @see #ABS_MIN_RANGE
		*/
		public function get xmin():Number { return _xmin; }
		/** @private */
		public function set xmin(n_xmin:Number):void {
			if(n_xmin >= _xmax)
				throw new RangeError("xmin must be strictly less than xmax");
			else if(Math.abs(_xmax - n_xmin) <= ABS_MIN_RANGE)
				throw new RangeError("range below minimum resolution");

			_xmin = n_xmin;
			invalidate(INV_RANGE);
		}
		
		[Bindable]
		[Inspectable(defaultValue = 10)]
		/**
		* The maximum x-value to show in the graph.
		* @default 10
		* @throws RangeError <code>RangeError</code>: either the value is
		*  less than or equal to <code>xmin</code> or the resulting range
		*  would be less than the minimum.
		* @see #ABS_MIN_RANGE
		*/
		public function get xmax():Number { return _xmax; }
		/** @private */
		public function set xmax(n_xmax:Number):void {
			if(n_xmax <= _xmin)
				throw new RangeError("xmax must be strictly greater than xmin");
			else if(Math.abs(n_xmax - _xmin) <= ABS_MIN_RANGE)
				throw new RangeError("range below minimum resolution");

			_xmax = n_xmax;
			invalidate(INV_RANGE);
		}

		[Bindable]
		[Inspectable(defaultValue = -10)]
		/**
		* The minimum y-value to show in the graph.
		* @default -10
		* @throws RangeError <code>RangeError</code>: either the value is
		*  greater than or equal to <code>ymax</code> or the resulting range
		*  would be less than the minimum.
		* @see #ABS_MIN_RANGE
		*/
		public function get ymin():Number { return _ymin; }
		/** @private */
		public function set ymin(n_ymin:Number):void {
			if(n_ymin >= _ymax)
				throw new RangeError("ymin must be strictly less than ymax");
			else if(Math.abs(_ymax - n_ymin) <= ABS_MIN_RANGE)
				throw new RangeError("range below minimum resolution");

			_ymin = n_ymin;
			invalidate(INV_RANGE);
		}

		[Bindable]
		[Inspectable(defaultValue = 10)]
		/**
		* The maximum y-value to show in the graph.
		* @default 10
		* @throws RangeError <code>RangeError</code>: either the value is
		*  less than or equal to <code>ymin</code> or the resulting range
		*  would be less than the minimum.
		* @see #ABS_MIN_RANGE
		*/
		public function get ymax():Number { return _ymax; }
		/** @private */
		public function set ymax(n_ymax:Number):void {
			if(n_ymax <= _ymin)
				throw new RangeError("ymax must be strictly greater than ymin");
			else if(Math.abs(n_ymax - _ymin) <= ABS_MIN_RANGE)
				throw new RangeError("range below minimum resolution");

			_ymax = n_ymax;
			invalidate(INV_RANGE);
		}
		
		[Bindable]
		[Inspectable(defaultValue = true)]
		/**
		* If true, display a border around the grapher. The thickness and color
		* of this border can be controlled with the <code>borderThickness</code>
		* and <code>borderColor</code> properties.
		* @default true
		* @see #borderThickness
		* @see #borderColor
		*/
		public function get showBorder():Boolean { return _showBorder; }
		/** @private */
		public function set showBorder(n_showBorder:Boolean):void {
			_showBorder = n_showBorder;
			drawBorder();
		}
		
		[Bindable]
		[Inspectable(defaultValue = 1)]
		/**
		* The thickness (in pixels) of the border around the grapher. A value
		* of 0 indicates a hairline. The <code>showBorder</code> property
		* controls the border's visibility.
		* @default 1
		* @see #showBorder
		*/
		public function get borderThickness():uint { return _borderThickness; }
		/** @private */
		public function set borderThickness(n_borderThickness:uint):void {
			_borderThickness = n_borderThickness;
			drawBorder();
		}
		
		[Bindable]
		[Inspectable(defaultValue = 0, type = "Color")]
		/** 
		* The color of the border around the grapher. The
		* <code>showBorder</code> property controls the border's visibility.
		* @default #000000 (black)
		* @see #showBorder
		*/
		public function get borderColor():uint { return _borderColor; }
		/** @private */
		public function set borderColor(n_borderColor:uint):void {
			_borderColor = n_borderColor;
			drawBorder();
		}
		
		[Bindable]
		[Inspectable(defaultValue = true)]
		/**
		* If true, show x- and y-axes in the grapher. The color and thickness
		* of the axes can be controlled with the <code>axesThickness</code> and
		* <code>axesColor</code> properties.
		* @default true
		* @see #axesThickness
		* @see #axesColor
		*/
		public function get showAxes():Boolean { return _showAxes; }
		/** @private */
		public function set showAxes(n_showAxes:Boolean):void {
			_showAxes = n_showAxes;
			drawAxesAndTicks();
		}
		
		[Bindable]
		[Inspectable(defaultValue = 1)]
		/**
		* The thickness of the lines used to draw the axes and tickmarks. A
		* value of 0 indicates a hairline. The <code>showAxes</code> property
		* controls the visibility of the axes, and the <code>tickStyle</code>
		* property manages tickmarks.
		* @default 1
		* @see #showAxes
		* @see #tickStyle
		*/
		public function get axesThickness():uint { return _axesThickness; }
		/** @private */
		public function set axesThickness(n_axesThickness:uint):void {
			_axesThickness = n_axesThickness;
			drawAxesAndTicks();
		}
		
		[Bindable]
		[Inspectable(defaultValue = "#990000", type = "Color")]
		/**
		* The color of the axes and tickmarks. The <code>showAxes</code>
		* property controls the visibility of the axes and the
		* <code>tickStyle</code> property manages tickmarks.
		* @default #990000 (red)
		* @see #showAxes
		* @see #tickStyle
		*/
		public function get axesColor():uint { return _axesColor; }
		public function set axesColor(n_axesColor:uint):void {
			_axesColor = n_axesColor;
			drawAxesAndTicks();
		}
		
		[Bindable]
		[Inspectable(defaultValue = "tickmarks", enumeration = "none, tickmarks, grid")]
		/**
		* The style of tickmarks to draw. This can be one of three values:
		* <ul>
		*  <li><code>Grapher2D.TICKSTYLE_NONE</code>: Don't draw tickmarks.</li>
		*  <li><code>Grapher2D.TICKSTYLE_TICKMARKS</code>: Draw small tickmarks
		*    originating from the axes.</li>
		*  <li><code>Grapher2D.TICKSTYLE_GRID</code>: Draw a light grid spaced
		*    as tickmarks would be.</li>
		* </ul>
		* The spacing of tickmarks is controlled by the <code>tickDx</code> and
		* <code>tickDy</code> properties. Note that tickmarks will not be drawn
		* if they would be less than 1 pixel apart.
		* @default Grapher2D.TICKSTYLE_TICKMARKS
		* @see #tickDx
		* @see #tickDy
		* @throws ArgumentError <code>ArgumentError</code>: The given value is
		*  not a valid tick style.
		*/
		public function get tickStyle():String { return _tickStyle; }
		/** @private */
		public function set tickStyle(n_tickStyle:String):void {
			if(n_tickStyle == TICKSTYLE_NONE || n_tickStyle == TICKSTYLE_TICKMARKS || n_tickStyle == TICKSTYLE_GRID) {
				_tickStyle = n_tickStyle;
				drawAxesAndTicks();
			}
			else
				throw new ArgumentError("invalid tick style");
		}
		
		[Bindable]
		[Inspectable(defaultValue = 1)]
		/**
		* The spacing of tickmarks along the x-axis. Note that tickmarks will
		* not be drawn if they would be less than 1 pixel apart.
		* @default 1
		* @throws RangeError <code>RangeError</code>: The given value is less
		*  than or equal to 0.
		*/
		public function get tickDx():Number { return _tickDx; }
		/** @private */
		public function set tickDx(n_tickDx:Number):void {
			if(n_tickDx <= 0) throw new RangeError("tick dx must be > 0");

			_tickDx = n_tickDx;
			drawAxesAndTicks();
		}
		
		[Bindable]
		[Inspectable(defaultValue = 1)]
		/**
		* The spacing of tickmarks along the y-axis. Note that tickmarks will
		* not be drawn if they would be less than 1 pixel apart.
		* @default 1
		* @throws RangeError <code>RangeError</code>: The given value is less
		*  than or equal to 0.
		*/
		public function get tickDy():Number { return _tickDy; }
		/** @private */
		public function set tickDy(n_tickDy:Number):void {
			if(n_tickDy <= 0) throw new RangeError("tick dy must be > 0");

			_tickDy = n_tickDy;
			drawAxesAndTicks();
		}		
	}
}