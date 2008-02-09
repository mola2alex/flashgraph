package {
	import mathlib.grapher.*;
	import mathlib.expr.*;
	import fl.events.*;
	import flash.events.*;
	import flash.display.*;
	import flash.ui.Keyboard;
	import flash.geom.Point;

	public class GraphDemo extends Sprite {
		// The grapher
		var grapher:Grapher2D;
	
		// Variables for the function graph.
		var expEnv:Environment = new Environment("x");
		var compFn:CompiledFn, fnGraph:FnGraph;
		var fnGraphLineStyle:LineStyle = new LineStyle(1, 0x6666CC);
		
		// Variables for the point graph
		var ptGraph:PtGraph;
		var ptGraphLineStyle:LineStyle = new LineStyle(1, 0x00FF00);

		// Constants for various defaults
		const ZOOM_FACTOR:Number = 2;
		const DEF_XMIN:Number = -10, DEF_XMAX:Number = 10;
		const DEF_YMIN:Number = -5, DEF_YMAX:Number = 15;
		const SNAP_TOLERANCE:Number = 0.5;

		// The function to graph.
		public function f(x:Number):Number {
			return 5 * Math.exp(Math.sin(x) / x) - 5;
		}

		public function GraphDemo():void {
			// Create and position the grapher.
			grapher = new Grapher2D();
			addChild(grapher);
			grapher.move(10, 10);
			grapher.setSize(580, 580);
			grapher.setFocus();
			
			// Install key handlers for the grapher--KEY_DOWN for ones that
			// repeat and KEY_UP for ones that don't.
			grapher.addEventListener(KeyboardEvent.KEY_DOWN, grapherKeyDownHandler);
			grapher.addEventListener(KeyboardEvent.KEY_UP, grapherKeyUpHandler);
			
			// Install click handler for adding to the point graph.
			grapher.addEventListener(MouseEvent.CLICK, grapherClickHandler);
			
			// And a double-click handler for recentering.
			grapher.addEventListener(MouseEvent.DOUBLE_CLICK, grapherDblClickHandler);
			
			// And finally, register a function to do draw the stage once it's
			// finished loading. We could do the things initDisplay does here in
			// the constructor, but there's no guarantee everything has loaded/
			// downloaded at this point.
			loaderInfo.addEventListener(Event.COMPLETE, initDisplay);
		}
		
		// Set up onscreen elements.
		function initDisplay(e:Event):void {
			grapher.borderColor = 0xDEDEDE;
			grapher.setRange(DEF_XMIN, DEF_XMAX, DEF_YMIN, DEF_YMAX);

			// Add the graphs: one of f(x) and an empty point graph.
			fnGraph = grapher.addFnGraph(f, fnGraphLineStyle);
			ptGraph = grapher.addPtGraph([], true, true, ptGraphLineStyle);
		}
		
		// Rounds the given number to the closest multiple of tolerance. This is
		// used to snap clicked points for the point graph.
		function snap(coord:Number, tolerance:Number = SNAP_TOLERANCE):Number {
			return Math.round(coord / tolerance) * tolerance;
		}


		// Event Handlers
		
		// Key down handler: handles repeating keyboard events, namely range
		// nudges from the arrow keys.
		function grapherKeyDownHandler(e:KeyboardEvent):void {
			var xchange:Number = Math.abs(grapher.xmax - grapher.xmin) / 10;
			var ychange:Number = Math.abs(grapher.ymax - grapher.ymin) / 10;
		
			switch(e.keyCode) {
				case Keyboard.UP:
				grapher.setYRange(grapher.ymin + ychange, grapher.ymax + ychange);
				break;

				case Keyboard.DOWN:
				grapher.setYRange(grapher.ymin - ychange, grapher.ymax - ychange);
				break;
					
				case Keyboard.RIGHT:
				grapher.setXRange(grapher.xmin + xchange, grapher.xmax + xchange);
				break;
					
				case Keyboard.LEFT:
				grapher.setXRange(grapher.xmin - xchange, grapher.xmax - xchange);
				break;
			}
		}
		
		// Key up handler: handles non-repeating keyboard events, namely
		// zooming, resetting the range, and deleting the previous point.
		function grapherKeyUpHandler(e:KeyboardEvent):void {
			if(e.charCode == 0)
				switch(e.keyCode) {
					case Keyboard.NUMPAD_ADD:
					grapher.zoom(1 / ZOOM_FACTOR, NaN, NaN, false);
					break;

					case Keyboard.NUMPAD_SUBTRACT:
					grapher.zoom(ZOOM_FACTOR, NaN, NaN, false);
					break;
				
					case Keyboard.NUMPAD_0:
					grapher.setRange(DEF_XMIN, DEF_XMAX, DEF_YMIN, DEF_YMAX);
					break;
				}
			else
				switch(String.fromCharCode(e.charCode)) {
					case '+':
					case '=':
					grapher.zoom(1 / ZOOM_FACTOR, NaN, NaN, false);
					break;
					
					case '-':
					case '_':
					grapher.zoom(ZOOM_FACTOR, NaN, NaN, false);
					break;

					case '0':
					grapher.setRange(DEF_XMIN, DEF_XMAX, DEF_YMIN, DEF_YMAX);
					break;
					
					case ' ':
					// Note that we have to manually call redraw() after
					// modifying the pts array.
					ptGraph.pts.pop();
					ptGraph.redraw();
					break;
				}
		}
		
		// Click handler: a shift-click adds a point to the point graph.
		function grapherClickHandler(e:MouseEvent):void {
			if(e.shiftKey) {
				// We have to convert from the local coordinates to ones in
				// the graph. Also note the snap to round to the nearest .5.
				var gx:Number = snap(grapher.localXToGraphX(e.localX));
				var gy:Number = snap(grapher.localYToGraphY(e.localY));
				ptGraph.addPoint(gx, gy);
			}
		}
		
		// Double-click handler: zoom about the clicked point.
		function grapherDblClickHandler(e:MouseEvent):void {
			var gx:Number = grapher.localXToGraphX(e.localX);
			var gy:Number = grapher.localYToGraphY(e.localY);
			grapher.centerAbout(gx, gy);
		}
	}
}
