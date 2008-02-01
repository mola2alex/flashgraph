﻿package mathlib.grapher {
	import flash.display.Sprite;
	import flash.geom.Point;
	
	public class PtGraph extends Sprite {
		public var pts:Array, parentGrapher:Grapher2D, lineStyle:LineStyle;
		public var connected:Boolean, showPoints:Boolean;
		
		public function PtGraph(n_parentGrapher:Grapher2D, n_pts:Array, n_connected:Boolean = true, n_showPoints:Boolean = true, n_lineStyle:LineStyle = null):void {
			super();
			
			parentGrapher = n_parentGrapher;
			pts = n_pts;
			connected = n_connected;
			showPoints = n_showPoints;
			
			if(n_lineStyle == null) lineStyle = LineStyle.Hairline;
			else lineStyle = n_lineStyle;
			
			doubleClickEnabled = true;
		}
		
		public function draw():void {
			var i:int, pt:Point;
			
			lineStyle.apply(graphics);
			
			for(i = 0; i < pts.length; i++) {
				pt = pts[i];
			
				if(showPoints) {
					//graphics.beginFill(lineStyle.color);
					parentGrapher.graphDrawPoint(graphics, pt.x, pt.y);
					//graphics.endFill();
				}
				if(connected && i > 0) {
					var ppt:Point = pts[i - 1];
					if(!(parentGrapher.isOutside(pt) && parentGrapher.isOutside(ppt))) {
						parentGrapher.graphMoveTo(graphics, ppt.x, ppt.y);
						parentGrapher.graphLineTo(graphics, pt.x, pt.y);
					}
				}
			}
		}
		
		public function redraw():void {
			graphics.clear();
			draw();
		}
		
		public function addPoint(graphx:Number, graphy:Number):void {
			pts.push(new Point(graphx, graphy));
			redraw();
		}
	}
}