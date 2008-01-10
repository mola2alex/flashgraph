﻿package mathlib.grapher {	import flash.display.Sprite;	public class FnGraph extends Sprite {		public var fn:Function, parentGrapher:Grapher2D, lineStyle:LineStyle;		public function FnGraph(n_parentGrapher:Grapher2D, n_fn:Function, n_lineStyle:LineStyle = null):void {			super();			fn = n_fn;			parentGrapher = n_parentGrapher;						if(n_lineStyle == null) lineStyle = LineStyle.Hairline;			else lineStyle = n_lineStyle;			doubleClickEnabled = true;		}				public function draw():void {			const xstep:Number = 1 / (parentGrapher.xres * parentGrapher.dx);			var curx:Number, cury:Number;			var oldx:Number, oldy:Number;			lineStyle.apply(graphics);			// this seems pretty sensible.  maybe implement "pickup" for discontinuities			// ripe for optimization.  timing test?  necessary?			oldx = parentGrapher.xmin;			oldy = fn(oldx);						//trace("xstep:", xstep);			for (curx = parentGrapher.xmin + xstep; curx <= parentGrapher.xmax; curx += xstep) {				cury = fn(curx);				if (parentGrapher.isDrawableY(oldy) && parentGrapher.isDrawableY(cury) && !parentGrapher.segmentOutOfBounds(cury, oldy)) {					parentGrapher.graphMoveTo(graphics, oldx, parentGrapher.truncateYIfNecessary(oldy));					parentGrapher.graphLineTo(graphics, curx, parentGrapher.truncateYIfNecessary(cury));					//trace("(" + oldx + ", " + oldy + ") -> (" + curx + ", " + cury + ")");				}				oldx = curx;				oldy = cury;			}		}				public function redraw():void {			graphics.clear();			draw();		}	}}