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
		var expEnv:Environment = new Environment("x");
		var compFn:CompiledFn, fnGraph:FnGraph;
		var fnGraphLineStyle:LineStyle = new LineStyle(1, 0x6666CC);
		
		var tangentPt:Point = new Point(), tangentGraph:FnGraph, tangentPtGraph:PtGraph;
		var tangentPtLineStyle:LineStyle = new LineStyle(2, 0xFF0000);
		var tangentGraphLineStyle:LineStyle = new LineStyle(1, 0x00FF00);

		const ZOOM_FACTOR:Number = 2, NUM_RESTRICT:String = "-.0123456789";
		const DEF_FN:String = "sin(x) + sin(50000x)/50000"/*".5x - x^3/8"*/, DEF_XVAL:Number = 2, DEF_SLOPE:Number = -1;
		const DEF_XMIN:Number = -1, DEF_XMAX:Number = 9, DEF_YMIN:Number = -6, DEF_YMAX:Number = 4;
		const DEF_DTICK:Number = 1;
		
		// crashing when xrange yrange = 5.684341886080802e-14 1.1368683772161603e-13
		
		public function MagnifyClass():void {
			slopeText.restrict = NUM_RESTRICT;
			xvalText.restrict  = NUM_RESTRICT;
			
			slopeSlider.addEventListener(SliderEvent.CHANGE, slopeSliderChangeHandler);
			slopeSlider.addEventListener(KeyboardEvent.KEY_DOWN, slopeSliderKeyHandler);
			
			slopeText.addEventListener(KeyboardEvent.KEY_UP, slopeTextKeyHandler);
			xvalText.addEventListener(KeyboardEvent.KEY_UP, xvalTextKeyHandler);
			fnText.addEventListener(KeyboardEvent.KEY_UP, fnTextKeyHandler);
			
			zoomInBtn.addEventListener(MouseEvent.CLICK, zoomInClickHandler);
			zoomOutBtn.addEventListener(MouseEvent.CLICK, zoomOutClickHandler);
			resetZoomBtn.addEventListener(MouseEvent.CLICK, resetZoomClickHandler);
			
			loaderInfo.addEventListener(Event.COMPLETE, initDisplay);
		}
		
		function initDisplay(e:Event):void {
			fnText.text = DEF_FN;
			xvalText.text = DEF_XVAL.toString();
			slopeSlider.value = DEF_SLOPE;
			
			grapher.setRange(DEF_XMIN, DEF_XMAX, DEF_YMIN, DEF_YMAX);
			
			drawFn();
			dispatchSlopeChange();
			updateTangentPoint();
			drawTangent();
		}

		function tangentLine(x:Number):Number {
			return tangentPt.y + slopeSlider.value * (x - tangentPt.x);
		}
		
		function drawTangent():void {	
			if(!tangentGraph)
				tangentGraph = grapher.addFnGraph(tangentLine, tangentGraphLineStyle);
			else
				tangentGraph.redraw();
				
			if(!tangentPtGraph)
				tangentPtGraph = grapher.addPtGraph([tangentPt], false, true, tangentPtLineStyle);
			else
				tangentPtGraph.redraw();
		}
		
		function updateTangentPoint():void {
			tangentPt.x = parseFloat(xvalText.text);
			tangentPt.y = compFn.eval(tangentPt.x);
			grapher.centerAbout(tangentPt.x, tangentPt.y);
		}
		
		function drawFn():void {
			compFn = Compiler.compile(expEnv, fnText.text);
			if(fnGraph)	grapher.removeGraph(fnGraph);
		
			fnGraph = grapher.addFnGraph(compFn.eval, fnGraphLineStyle)
		}
		
		
		
		// Event Handlers
		
		function slopeSliderChangeHandler(e:SliderEvent):void {
			slopeText.text = slopeSlider.value.toString();
			drawTangent();
		}
		
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
		
		function slopeTextKeyHandler(e:KeyboardEvent):void {
			if(e.keyCode == Keyboard.ENTER) {
				slopeSlider.value = parseFloat(slopeText.text);
				dispatchSlopeChange();
			}
		}
		
		function xvalTextKeyHandler(e:KeyboardEvent):void {
			if(e.keyCode == Keyboard.ENTER) {
				updateTangentPoint();
				drawTangent();
			}
		}
		
		function fnTextKeyHandler(e:KeyboardEvent):void {
			if(e.keyCode == Keyboard.ENTER) {
				drawFn();
				updateTangentPoint();
				drawTangent();
			}
		}
		
		function zoomInClickHandler(e:MouseEvent):void { 
			grapher.zoom(1 / ZOOM_FACTOR);
		}
		
		function zoomOutClickHandler(e:MouseEvent):void {
			grapher.zoom(ZOOM_FACTOR);
		}
		
		function resetZoomClickHandler(e:MouseEvent):void {
			grapher.setRange(DEF_XMIN, DEF_XMAX, DEF_YMIN, DEF_YMAX, false);
			grapher.setTickDxy(DEF_DTICK, DEF_DTICK, false);
			grapher.centerAbout(tangentPt.x, tangentPt.y);
		}
		
		
		
		// Helpers
		
		// Makes the slope slider send a Change event.  I wouldn't normally do this, but it
		// felt right since we're emulating things (e.g., keypresses) that should have been
		// native in the component.
		function dispatchSlopeChange():void {
			slopeSlider.dispatchEvent(new SliderEvent(SliderEvent.CHANGE,
													  slopeSlider.value,
													  SliderEventClickTarget.THUMB,
													  InteractionInputType.KEYBOARD));
		}
	}
}
