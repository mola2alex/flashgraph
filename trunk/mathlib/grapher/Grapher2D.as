﻿package mathlib.grapher {
	import fl.core.UIComponent;
	import flash.display.*;
	import flash.geom.Point;
	import fl.events.ComponentEvent;
	import fl.managers.IFocusManagerComponent;
	
	public class Grapher2D extends UIComponent implements IFocusManagerComponent {
		private var _axesSh:Shape, _borderSh:Shape, _graphSp:Sprite, _maskSh:Shape, _hitArea:Sprite;
		private var _dx:Number, _dy:Number, _xres:Number = 1;
		private var _xmin:Number = -10, _xmax:Number = 10, _ymin:Number = -10, _ymax:Number = 10;
		private var _showBorder:Boolean = true, _borderThickness:uint = 1, _borderColor:uint = 0;
		private var _showAxes:Boolean = true, _axesThickness:uint = 1, _axesColor:uint = 0x990000;
		private var _tickStyle:String = TICKSTYLE_TICKMARKS, _tickDx:Number = 1, _tickDy:Number = 1;
		
		public static const TICKSTYLE_NONE:String = "none", TICKSTYLE_TICKMARKS:String = "tickmarks", TICKSTYLE_GRID:String = "grid";
		private static const TICKSIZE:uint = 5, MINTICKSTEP:uint = 3, GRIDTICKSALPHA:Number = 0.1;
		private static const INV_RANGE:String = "range", INV_CREATE:String = "create", INV_SIZE:String = "size";
		private static const ABS_MIN_RANGE:Number = 1e-12; //1e-14;

		public function Grapher2D() {
			super();
			
			_borderSh = new Shape();
			_axesSh = new Shape();
			_maskSh = new Shape();
			_graphSp = new Sprite();
			_hitArea = new Sprite();

			// layering: axes under graphs under border
			addChild(_graphSp);
			addChild(_axesSh);
			addChild(_borderSh);
			
			doubleClickEnabled = true;
			_graphSp.doubleClickEnabled = true;
			
			addChild(_maskSh);  // won't be displayed, but nees to be in the display list.  check the help
			_graphSp.mask = _maskSh;
			//_axesSh.mask = _maskSh;
			
			_hitArea.mouseEnabled = false;
			addChild(_hitArea);  // likewise needs to be in the display list, but that's not in the help.  it's alpha 0, though.
			hitArea = _hitArea;
			
			invalidate(INV_CREATE);
		}
		
		protected override function draw():void	{
			updateDxy();
			drawHitArea();
			drawMask();
			drawBorder();
			drawAxesAndTicks();
			drawGraphs();
		}
		
		private function drawHitArea():void {
			var hitGr:Graphics = _hitArea.graphics;
			
			hitGr.clear();			
			hitGr.beginFill(0, 0);
			hitGr.drawRect(0, 0, width, height);
			hitGr.endFill();
		}

		private function drawMask():void {
			var maskGr:Graphics = _maskSh.graphics;
			
			maskGr.clear();
			maskGr.beginFill(0xFFFFFF);
			maskGr.drawRect(0, 0, width, height);
			maskGr.endFill();
		}
		
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
		
		private function drawTicksInto(gr:Graphics):void {
			var i:Number, xorigin:Number, yorigin:Number;
			var txstep:Number = _tickDx * _dx, tystep:Number = _tickDy * _dy;  // physical (pixel) distance between adjacent tickmarks
			var firstXTick:Number = _tickDx * Math.ceil(_xmin / _tickDx);
			var firstYTick:Number = _tickDy * Math.ceil(_ymin / _tickDy);
		
			//trace("firstXTick:", firstXTick, "xmin:", _xmin, "xmax:", _xmax);
			//trace("firstYTick:", firstYTick, "ymin:", _ymin, "ymax:", _ymax);

			if(_tickStyle == TICKSTYLE_TICKMARKS) {
				xorigin = graphXToLocalX(0);
				yorigin = graphYToLocalY(0);
				
				// x-axis tickmarks (i.e., perpendicular to the x-axis)
				if(_ymin <= 0 && _ymax >= 0 && txstep > MINTICKSTEP) {
					for(i = firstXTick; i <= _xmax; i += _tickDx) {
						graphMoveTo(gr, i, 0);
						gr.lineTo(graphXToLocalX(i), yorigin - TICKSIZE);
					}
				}
				
				// y-axis tickmarks (i.e., perpendicular to the y-axis)
				if(_xmin <= 0 && _xmax >= 0 && tystep > MINTICKSTEP) {
					for(i = firstYTick; i <= _ymax; i += _tickDy) {
						graphMoveTo(gr, 0, i);
						gr.lineTo(xorigin + TICKSIZE, graphYToLocalY(i));
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
			
		
		private function drawBorder():void {
			var borderGr:Graphics = _borderSh.graphics;
			
			borderGr.clear();
			
			if(_showBorder) {
				borderGr.lineStyle(_borderThickness, _borderColor, 1, true, LineScaleMode.NONE, CapsStyle.NONE, JointStyle.MITER);
				borderGr.drawRect(0, 0, width, height);
			}
		}
	
		private function drawGraphs():void {
			var i:int, child:*;
			
			for(i = 0; i < _graphSp.numChildren; i++) {
				child = _graphSp.getChildAt(i);
				child.redraw();
			}
		}
		
		public function removeGraph(graph:DisplayObject):DisplayObject {
			return _graphSp.removeChild(graph);
		}
		
		public function addFnGraph(fn:Function, lineStyle:LineStyle = null):FnGraph {
			var fg:FnGraph = new FnGraph(this, fn, lineStyle);
			_graphSp.addChild(fg);
			fg.draw();
			
			return fg;
		}
		
		public function addPtGraph(pts:Array, connected:Boolean = true, showPoints:Boolean = true, lineStyle:LineStyle = null):PtGraph {
			var pg:PtGraph = new PtGraph(this, pts, connected, showPoints, lineStyle);
			_graphSp.addChild(pg);
			pg.draw();
			
			return pg;
		}
		
		internal function graphMoveTo(gr:Graphics, graphx:Number, graphy:Number):void {
			gr.moveTo(graphXToLocalX(graphx), graphYToLocalY(graphy));
		}
		
		internal function graphLineTo(gr:Graphics, graphx:Number, graphy:Number):void {
			gr.lineTo(graphXToLocalX(graphx), graphYToLocalY(graphy));
		}
		
		internal function graphDrawPoint(gr:Graphics, graphx:Number, graphy:Number):void {
			gr.drawCircle(graphXToLocalX(graphx), graphYToLocalY(graphy), 2);
		}
		
		internal function isOutside(pt:Point):Boolean {
            return pt.x > _xmax || pt.x < _xmin ||
                   pt.y > _ymax || pt.y < _ymin;
        }
		
		internal function isSegmentOutside(cury:Number, oldy:Number):Boolean {
			return (cury > _ymax && oldy > _ymax) ||
				   (cury < _ymin && oldy < _ymin);
		}
		
		internal function isDrawableY(graphy:Number):Boolean {
			return !isNaN(graphy) && isFinite(graphy);
		}
		
		private function updateDxy():void {
			_dx = width / (_xmax - _xmin);
			_dy = height / (_ymax - _ymin);
		}
		
		public function zoom(factor:Number, graphx:Number = NaN, graphy:Number = NaN, zoomTicks:Boolean = true):void {
			if(factor <= 0) throw new ArgumentError("zoom factor must be > 0");
				
			var xdiff:Number = Math.abs(_xmax - _xmin) * factor / 2;
			var ydiff:Number = Math.abs(_ymax - _ymin) * factor / 2;
			
			// if a center point isn't specified, use the center of the graph window
			if(isNaN(graphx)) graphx = localXToGraphX(width / 2);
			if(isNaN(graphy)) graphy = localYToGraphY(height / 2);
			

			setRange(graphx - xdiff, graphx + xdiff, graphy - ydiff, graphy + ydiff, false);
			if(zoomTicks) {
				_tickDx *= factor;
				_tickDy *= factor;
			}

			invalidate(INV_RANGE);
		}
		
		public function centerAbout(graphx:Number, graphy:Number):void {
			zoom(1, graphx, graphy);
		}
		
	
		// Point conversion
		public function graphXToLocalX(graphx:Number):Number { return _dx * (graphx - _xmin); }
		public function graphYToLocalY(graphy:Number):Number { return _dy * (_ymax - graphy); }
		public function graphToLocal(graphpt:Point):Point {
			return new Point(graphXToLocalX(graphpt.x), graphYToLocalY(graphpt.y));
		}
		
		public function localXToGraphX(localx:Number):Number { return _xmin + localx / _dx; }
		public function localYToGraphY(localy:Number):Number { return _ymax - localy / _dy; }
		public function localToGraph(localpt:Point):Point {
			return new Point(localXToGraphX(localpt.x), localXToGraphX(localpt.y));
		}
		
		public function globalToGraph(globalpt:Point):Point {
			return localToGraph(globalToLocal(globalpt));
		}
		public function graphToGlobal(graphpt:Point):Point {
			return localToGlobal(graphToLocal(graphpt));
		}
		

		
		// Getters & Setters
		public function setXRange(n_xmin:Number, n_xmax:Number, doRedraw:Boolean = true):void {
			if(n_xmin >= n_xmax)
				throw new RangeError("xmin must be strictly less than xmax");
			if(Math.abs(n_xmax - n_xmin) <= ABS_MIN_RANGE)
				throw new RangeError("range below minimum resolution");

			_xmin = n_xmin;
			_xmax = n_xmax;
			if(doRedraw) invalidate(INV_RANGE);
		}
		
		public function setYRange(n_ymin:Number, n_ymax:Number, doRedraw:Boolean = true):void {
			if(n_ymin >= n_ymax)
				throw new RangeError("ymin must be strictly less than ymax");
			if(Math.abs(n_ymax - n_ymin) <= ABS_MIN_RANGE)
				throw new RangeError("range below minimum resolution");

			_ymin = n_ymin;
			_ymax = n_ymax;
			if(doRedraw) invalidate(INV_RANGE);
		}
		
		public function setRange(n_xmin:Number, n_xmax:Number, n_ymin:Number, n_ymax:Number, doRedraw:Boolean = true):void {
			setXRange(n_xmin, n_xmax, false);
			setYRange(n_ymin, n_ymax, doRedraw);
		}
		
		public function setTickDxy(n_tickDx:Number, n_tickDy:Number, doRedraw:Boolean = true):void {
			if(n_tickDx <= 0 || n_tickDy <= 0)
				throw new RangeError("tick spacings must be > 0");

			_tickDx = n_tickDx;
			_tickDy = n_tickDy;
			if(doRedraw) drawAxesAndTicks();
		}
		
		public function get dx():Number { return _dx; }
		public function get dy():Number { return _dy; }
		
		[Bindable]
		[Inspectable(defaultValue = 1)]
		public function get xres():Number { return _xres; }
		public function set xres(n_xres:Number):void {
			if(n_xres <= 0)
				throw new RangeError("xres must be a positive number");

			_xres = n_xres;
			drawGraphs();
		}
		
		[Bindable]
		[Inspectable(defaultValue = -10)]
		public function get xmin():Number { return _xmin; }
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
		public function get xmax():Number { return _xmax; }
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
		public function get ymin():Number { return _ymin; }
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
		public function get ymax():Number { return _ymax; }
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
		public function get showBorder():Boolean { return _showBorder; }
		public function set showBorder(n_showBorder:Boolean):void {
			_showBorder = n_showBorder;
			drawBorder();
		}
		
		[Bindable]
		[Inspectable(defaultValue = 1)]
		public function get borderThickness():uint { return _borderThickness; }
		public function set borderThickness(n_borderThickness:uint):void {
			_borderThickness = n_borderThickness;
			drawBorder();
		}
		
		[Bindable]
		[Inspectable(defaultValue = 0, type = "Color")]
		public function get borderColor():uint { return _borderColor; }
		public function set borderColor(n_borderColor:uint):void {
			_borderColor = n_borderColor;
			drawBorder();
		}
		
		[Bindable]
		[Inspectable(defaultValue = true)]
		public function get showAxes():Boolean { return _showAxes; }
		public function set showAxes(n_showAxes:Boolean):void {
			_showAxes = n_showAxes;
			drawAxesAndTicks();
		}
		
		[Bindable]
		[Inspectable(defaultValue = 1)]
		public function get axesThickness():uint { return _axesThickness; }
		public function set axesThickness(n_axesThickness:uint):void {
			_axesThickness = n_axesThickness;
			drawAxesAndTicks();
		}
		
		[Bindable]
		[Inspectable(defaultValue = "#990000", type = "Color")]
		public function get axesColor():uint { return _axesColor; }
		public function set axesColor(n_axesColor:uint):void {
			_axesColor = n_axesColor;
			drawAxesAndTicks();
		}
		
		[Bindable]
		[Inspectable(defaultValue = "tickmarks", enumeration = "none, tickmarks, grid")]
		public function get tickStyle():String { return _tickStyle; }
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
		public function get tickDx():Number { return _tickDx; }
		public function set tickDx(n_tickDx:Number):void {
			if(n_tickDx <= 0) throw new RangeError("tick dx must be > 0");

			_tickDx = n_tickDx;
			drawAxesAndTicks();
		}
		
		[Bindable]
		[Inspectable(defaultValue = 1)]
		public function get tickDy():Number { return _tickDy; }
		public function set tickDy(n_tickDy:Number):void {
			if(n_tickDy <= 0) throw new RangeError("tick dy must be > 0");

			_tickDy = n_tickDy;
			drawAxesAndTicks();
		}		
	}
}