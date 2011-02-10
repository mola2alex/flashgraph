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

		// Constants for various defaults
		const NUM_RESTRICT:String = "-.0123456789";
		const INT_RESTRICT:String = "-0123456789";
		const ZOOM_FACTOR:Number = 2;
		const DEF_FN:String = "sin(x) + sin(50000x)/50000"
		const DEF_XVAL:Number = 2;
		const DEF_SLOPE:Number = -1;
		const DEF_ZOOM:int = 0;
		const DEF_XMIN:Number = -1, DEF_XMAX:Number = 9;
		const DEF_YMIN:Number = -6, DEF_YMAX:Number = 4;
		const DEF_DTICK:Number = 1;
		
		public function MagnifyClass():void {
			// Limit the slope and xval textboxes to numeric characters
			slopeText.restrict = NUM_RESTRICT;
			xvalText.restrict  = NUM_RESTRICT;
			zoomText.restrict  = INT_RESTRICT; 
			
			// Register functions to be called when the slider is changed or
			// a key is pressed while it's active. The Slider component has an
			// annoying issue... it will only deal with keypresses if the
			// snapInterval is an integer. So we have to work around that with
			// some event twiddling.
			slopeSlider.addEventListener(SliderEvent.CHANGE, slopeSliderChangeHandler);
			slopeSlider.addEventListener(KeyboardEvent.KEY_DOWN, slopeSliderKeyHandler);

			// Register a function for when the zoom slider changes its value.
			zoomSlider.addEventListener(SliderEvent.CHANGE, zoomSliderChangeHandler);
			
			// Register functions to be called when a key is pressed in one of
			// the input textboxes.
			slopeText.addEventListener(KeyboardEvent.KEY_UP, slopeTextKeyHandler);
			zoomText.addEventListener(KeyboardEvent.KEY_UP, zoomTextKeyHandler);
			xvalText.addEventListener(KeyboardEvent.KEY_UP, xvalTextKeyHandler);
			fnText.addEventListener(KeyboardEvent.KEY_UP, fnTextKeyHandler);

			// Hide the error panel and register hooks to close it when the user
			// clicks the close button or types a letter with it focused
			errorPanel.visible = false;
			errorPanel.closeBtn.useHandCursor = true;
			errorPanel.closeBtn.addEventListener(MouseEvent.CLICK, closeBtnHandler);
			errorPanel.msgText.addEventListener(KeyboardEvent.KEY_UP, closeBtnHandler);
			
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
			slopeText.text = DEF_SLOPE.toString();
			zoomSlider.value = DEF_ZOOM;
			zoomText.text = DEF_ZOOM.toString();
			
			grapher.setRange(DEF_XMIN, DEF_XMAX, DEF_YMIN, DEF_YMAX);
			
			updateFn();
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
			var newX:Number = parseFloat(xvalText.text);
			
			// If there's an error, alert the user.
			if(isNaN(newX))
				showErrorPanel("Unable to parse x value as a number.");
			else {
				tangentPt.x = parseFloat(xvalText.text);
				tangentPt.y = compFn.eval(tangentPt.x);
				grapher.centerAbout(tangentPt.x, tangentPt.y);
			}
		}
		
		// Recompile and draw the given function.
		function updateFn():void {
			// Try to parse the function, but show the error and bail if needed.
			try {
				compFn = Compiler.compile(expEnv, fnText.text);
			}
			catch(err:SyntaxError) {
				showErrorPanel(err.message);
				return;
			}

			// Add a new graph if one didn't already exist (the first time we're
			// called).
			if(!fnGraph)
				fnGraph = grapher.addFnGraph(compFn.eval, fnGraphLineStyle);
		
			// Otherwise just update the function.
			fnGraph.fn = compFn.eval;
		}
		
		// Zoom the graph to the appropriate zoomSlider setting.
		function zoomGraph():void {
			var level:int = zoomSlider.value;
			var zoomFactor:Number;
			
			// The grapher component views zoom factors as multipliers on the
			// range, so convert our integers to that.
			if(level < 0)
				zoomFactor = Math.pow(ZOOM_FACTOR, -level);
			else if(level > 0)
				zoomFactor = 1 / Math.pow(ZOOM_FACTOR, level);
			else
				zoomFactor = 1;

			// We have to think about the zoom factor relative to the starting
			// setup, so go back to that. The falses save the intermediate
			// redraws. Then, we zoom to the factor we found, centering on the
			// tangent point. This last call redraws the grapher.
			grapher.setRange(DEF_XMIN, DEF_XMAX, DEF_YMIN, DEF_YMAX, false);
			grapher.setTickDxy(DEF_DTICK, DEF_DTICK, false);
			grapher.zoom(zoomFactor, tangentPt.x, tangentPt.y);
		}
		
		
		// Event Handlers
		
		// When the user changes the slider, update the textbox and redraw the
		// tangent line.
		function slopeSliderChangeHandler(e:SliderEvent):void {
			slopeText.text = slopeSlider.value.toString();
			drawTangent();
		}
		
		// Handle keyboard input for the slider control. This should happen
		// automatically, but the CS3 Slider component doesn't like to do
		// keyboard input with non-integer snapIntervals.
		function slopeSliderKeyHandler(e:KeyboardEvent):void {
			switch(e.keyCode) {
				case Keyboard.LEFT:
				case Keyboard.DOWN:
					slopeSlider.value -= slopeSlider.snapInterval;
					slopeText.text = slopeSlider.value.toString();
					drawTangent();
				break;
				
				case Keyboard.RIGHT:
				case Keyboard.UP:
					slopeSlider.value += slopeSlider.snapInterval;
					slopeText.text = slopeSlider.value.toString();
					drawTangent();
				break;
			}
		}
		
		// When the user hits enter in the slope textbox, update the slider.
		function slopeTextKeyHandler(e:KeyboardEvent):void {
			if(e.keyCode == Keyboard.ENTER) {
				var newSlope:Number = parseFloat(slopeText.text);

				// Check for an error and show a message if needed.
				if(isNaN(newSlope))
					showErrorPanel("Unable to parse slope as number.");
				else {
					slopeSlider.value = newSlope;
					// Write back the parsed float to the field. This cleans up
					// the input if there were extraneous (but parsable) things.
					slopeText.text = newSlope.toString();
					drawTangent();
				}
			}
		}
		
		// When the user changes the zoom slider, tell the grapher about it.
		function zoomSliderChangeHandler(e:SliderEvent):void {
			zoomText.text = zoomSlider.value.toString();
			zoomGraph();
		}
		
		// When the user hits enter in the zoom textbox, update the slider.
		function zoomTextKeyHandler(e:KeyboardEvent):void {
			if(e.keyCode == Keyboard.ENTER) {
				var newZoom:int = parseInt(zoomText.text);
				
				// Check for an error and show a message if needed.
				if(isNaN(newZoom))
					showErrorPanel("Unable to parse zoom level as integer");
				else {
					zoomSlider.value = newZoom;
					zoomText.text = newZoom.toString();
					zoomGraph();
				}
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
		
		
		// Error Panel Helpers
		
		// Pop up the error panel with the given message. Sets the focus to the
		// text field in the panel so that a keypress will dismiss it.
		function showErrorPanel(err:String):void {
			errorPanel.msgText.text = err;
			errorPanel.visible = true;
			stage.focus = errorPanel.msgText;
		}
		
		// Hide the error panel.
		function closeBtnHandler(e:Event):void {
			errorPanel.visible = false;
		}
	}
}
