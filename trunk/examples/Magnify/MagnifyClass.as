package {
	import mathlib.grapher.*;
	import mathlib.expr.*;
	import fl.events.*;
	import flash.events.*;
	import flash.display.*;
	import flash.ui.Keyboard;
	import flash.geom.Point;
	import flash.text.TextField;
	
	public class MagnifyClass extends Sprite {
		// Variables for the function graph.
		var expEnv:Environment = new Environment("x");
		var compFn:CompiledFn, fnGraph:FnGraph;
		var fnGraphLineStyle:LineStyle = new LineStyle(1, 0x6666CC);
		
		// Variables for the tangent point and tangent line
		var tangentPt:Point = new Point();
		var tangentGraph:FnGraph;
		var tangentPtGraph:PtGraph;
		var tangentPtLineStyle:LineStyle = new LineStyle(2, 0xFF0000);
		var tangentGraphLineStyle:LineStyle = new LineStyle(1, 0x00FF00);
		
		// Zoom accounting
		var zoomLevel:int = 0;

		// Constants for various defaults
		const NUM_RESTRICT:String = "-.0123456789";
		const ZOOM_FACTOR:Number = 3;
		const DEF_FN:String = "sin(x) + sin(50000x)/50000"
		const DEF_XVAL:Number = 2;
		const DEF_SLOPE:Number = -1;
		const DEF_XMIN:Number = -1, DEF_XMAX:Number = 9;
		const DEF_YMIN:Number = -6, DEF_YMAX:Number = 4;
		const DEF_DTICK:Number = 1;
		const MAX_ZOOM_LEVEL:uint = 15;
		
		public function MagnifyClass():void {
			// Limit the slope and xval textboxes to numeric characters
			slopeText.restrict = NUM_RESTRICT;
			xvalText.restrict  = NUM_RESTRICT;
			
			// Register functions to be called when the slider is changed or
			// a key is pressed while it's active.
			slopeSlider.addEventListener(SliderEvent.CHANGE, slopeSliderChangeHandler);
			slopeSlider.addEventListener(KeyboardEvent.KEY_DOWN, slopeSliderKeyHandler);
			
			// Register functions to be called when a key is pressed in one of
			// the input textboxes.
			slopeText.addEventListener(KeyboardEvent.KEY_UP, slopeTextKeyHandler);
			xvalText.addEventListener(KeyboardEvent.KEY_UP, xvalTextKeyHandler);
			fnText.addEventListener(KeyboardEvent.KEY_UP, fnTextKeyHandler);
			
			// Register functions for button clicks.
			zoomInBtn.addEventListener(MouseEvent.CLICK, zoomInClickHandler);
			zoomOutBtn.addEventListener(MouseEvent.CLICK, zoomOutClickHandler);
			resetZoomBtn.addEventListener(MouseEvent.CLICK, resetZoomClickHandler);
			
			// And finally, register a function to do draw the stage once it's
			// finished loading. We could do the things initDisplay does here in
			// the constructor, but there's no guarantee everything has loaded/
			// downloaded at this point.
			loaderInfo.addEventListener(Event.COMPLETE, initDisplay);
		}
		
		// Set up onscreen elements.
		function initDisplay(e:Event):void {
			fnText.text = DEF_FN;
			xvalText.text = DEF_XVAL.toString();
			slopeSlider.value = DEF_SLOPE;
			
			grapher.setRange(DEF_XMIN, DEF_XMAX, DEF_YMIN, DEF_YMAX);
			
			updateFn();
			dispatchSlopeChange();
			updateTangentPoint();
			drawTangent();
		}

		// The function representing the graph of the tangent line.
		function tangentLine(x:Number):Number {
			return tangentPt.y + slopeSlider.value * (x - tangentPt.x);
		}
		
		// Draw the tangent line and point in the grapher.
		function drawTangent():void {
			if(!tangentGraph)
				// If we haven't already created the tangent graph, do so
				tangentGraph = grapher.addFnGraph(tangentLine, tangentGraphLineStyle);
			else
				// Otherwise, just redraw it. Its function (tangentLine above)
				// takes into account the current slope and tangent point.
				tangentGraph.redraw();
				
			// Draw the tangent point. Making it a PtGraph makes it persistent
			// across zooms.
			if(!tangentPtGraph)
				tangentPtGraph = grapher.addPtGraph([tangentPt], false, true, tangentPtLineStyle);
			else
				tangentPtGraph.redraw();
		}
		
		// Recalculate the tangent point given the new user-input x value and
		// recenter the graph around the new point.
		function updateTangentPoint():void {
			tangentPt.x = parseFloat(xvalText.text);
			tangentPt.y = compFn.eval(tangentPt.x);
			grapher.centerAbout(tangentPt.x, tangentPt.y);
		}
		
		// Recompile and draw the given function.
		function updateFn():void {
			compFn = Compiler.compile(expEnv, fnText.text);

			// Add a new graph if one didn't already exist (the first time we're
			// called).
			if(!fnGraph)
				fnGraph = grapher.addFnGraph(compFn.eval, fnGraphLineStyle);
		
			// Otherwise just update the function.
			fnGraph.fn = compFn.eval;
		}
		
		
		
		// Event Handlers
		
		// When the user changes the slider, update the textbox and redraw the
		// tangent line.
		function slopeSliderChangeHandler(e:SliderEvent):void {
			slopeText.text = slopeSlider.value.toString();
			drawTangent();
		}
		
		// Handle keyboard input for the slider control, moving by the smallest
		// increment (the snapInterval property).
		function slopeSliderKeyHandler(e:KeyboardEvent):void {	
			switch(e.keyCode) {
				case Keyboard.LEFT:
				case Keyboard.DOWN:
					slopeSlider.value -= slopeSlider.snapInterval;
					dispatchSlopeChange()
				break;
				
				case Keyboard.RIGHT:
				case Keyboard.UP:
					slopeSlider.value += slopeSlider.snapInterval;
					dispatchSlopeChange();
				break;
			}
		}
		
		// When the user hits enter in the slope textbox, update the slider.
		function slopeTextKeyHandler(e:KeyboardEvent):void {
			if(e.keyCode == Keyboard.ENTER) {
				slopeSlider.value = parseFloat(slopeText.text);
				dispatchSlopeChange();
			}
		}
		
		// When the user hits enter in the the x-value textbox, update the
		// tangent point and redraw the tangent line.
		function xvalTextKeyHandler(e:KeyboardEvent):void {
			if(e.keyCode == Keyboard.ENTER) {
				updateTangentPoint();
				drawTangent();
			}
		}
		
		// When the user hits enter in the function textbox, update everything.
		function fnTextKeyHandler(e:KeyboardEvent):void {
			if(e.keyCode == Keyboard.ENTER) {
				updateFn();
				updateTangentPoint();
				drawTangent();
			}
		}
		
		function zoomInClickHandler(e:MouseEvent):void {
			zoomLevel++;
			updateZoomButtons();

			grapher.zoom(1 / ZOOM_FACTOR);
		}
		
		function zoomOutClickHandler(e:MouseEvent):void {
			zoomLevel--;
			updateZoomButtons();

			grapher.zoom(ZOOM_FACTOR);
		}
		
		// Handle the zoom limiting logic by enabling/disabling buttons as
		// appropriate. The 
		function updateZoomButtons():void {
			trace(zoomLevel);
			if(zoomLevel >= MAX_ZOOM_LEVEL)
				zoomInBtn.enabled = false;
			else if(zoomLevel < 0 && -zoomLevel >= MAX_ZOOM_LEVEL)
				zoomOutBtn.enabled = false;
			else {
				zoomInBtn.enabled = true;
				zoomOutBtn.enabled = true;
			}
		}
		
		// Set graph view back to the default.
		function resetZoomClickHandler(e:MouseEvent):void {
			grapher.setRange(DEF_XMIN, DEF_XMAX, DEF_YMIN, DEF_YMAX, false);
			grapher.setTickDxy(DEF_DTICK, DEF_DTICK, false);
			grapher.centerAbout(tangentPt.x, tangentPt.y);

			zoomLevel = 0;
			updateZoomButtons();
		}
		
		
		
		// Helpers
		
		// Makes the slope slider send a Change event.  I wouldn't normally do
		// this, but it felt right since we're emulating things (e.g.,
		// keypresses) that should have been native in the component.
		function dispatchSlopeChange():void {
			slopeSlider.dispatchEvent(new SliderEvent(SliderEvent.CHANGE,
													  slopeSlider.value,
													  SliderEventClickTarget.THUMB,
													  InteractionInputType.KEYBOARD));
		}
	}
}
