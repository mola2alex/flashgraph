package {
	import mathlib.expr.*;
	import flash.events.*;
	import flash.display.*;
	import flash.ui.Keyboard;
	import flash.text.TextField;
	import fl.controls.List;
	import fl.data.DataProvider;
	
	public class ExprCalculator extends Sprite {
		var dp:DataProvider = new DataProvider();
		var env:Environment = new Environment("x", "y");
		const NUMRESTRICT:String = "-.0123456789";
		
		// Constructor; called when the movie starts.
		public function ExprCalculator():void {
			// Limit the allowed characters in the number input fields
			xText.restrict = NUMRESTRICT;
			yText.restrict = NUMRESTRICT;
			
			// Set up proper tab ordering and set focus to the function field
			xText.tabIndex = 1;
			yText.tabIndex = 2;
			fnText.tabIndex = 3;
			hist.tabIndex = 4;
			stage.focus = fnText;
			
			// Hide the error panel and register hooks to close it when the user
			// clicks the close button or types a letter with it focused
			errorPanel.visible = false;
			errorPanel.closeBtn.useHandCursor = true;
			errorPanel.closeBtn.addEventListener(MouseEvent.CLICK, closeBtnHandler);
			errorPanel.msgText.addEventListener(KeyboardEvent.KEY_UP, closeBtnHandler);
		
			// Add hooks to evaluate the function when enter is pressed in one
			// of the input fields.
			fnText.addEventListener(KeyboardEvent.KEY_UP, evalKeyHandler);
			xText.addEventListener(KeyboardEvent.KEY_UP, evalKeyHandler);
			yText.addEventListener(KeyboardEvent.KEY_UP, evalKeyHandler);
			
			// Add a hook to deal with the user clicking on a history entry.
			hist.addEventListener(Event.CHANGE, histChangeHandler);
		}
		
		// Called when the user hits a key in one of the input boxes
		function evalKeyHandler(e:KeyboardEvent):void {
			var cmpFn:CompiledFn;
			var xVal:Number, yVal:Number, fnVal:Number;
			var dpItem:Object;
		
			if(e.keyCode == Keyboard.ENTER) {
				// Convert the x/y inputs to numbers
				xVal = parseFloat(xText.text);
				yVal = parseFloat(yText.text);

				// If we had trouble parsing the input as numbers, pop up an
				// appropriate error message.
				if(isNaN(xVal)) {
					showErrorPanel("Could not parse x-value as a number.");
					return;
				}
				if(isNaN(yVal)) {
					showErrorPanel("Could not parse y-value as a number.");
					return;
				}
					
				// Set the fields back to the parsed number. This cleans
				// up things like extraneous periods and zeroes.
				xText.text = xVal.toString();
				yText.text = yVal.toString();

				// Try to parse the given function, showing the error if needed
				try {
					cmpFn = Compiler.compile(env, fnText.text);
				}
				catch(err:SyntaxError) {
					showErrorPanel(err.message);
					return;
				}				

				// Evaluate the function at the input coordinate
				fnVal = cmpFn.eval(xVal, yVal);

				// Add a new item to the history list
				dpItem = {label: fnText.text + " @ (" + xText.text +
							     ", " + yText.text + ") = " +
				                 fnVal.toString(),
				          fnText: fnText.text,
				          xText: xText.text,
				          yText: yText.text};
					          
				dp.addItem(dpItem);
				hist.dataProvider = dp;
				
				// Scroll to the bottom of the history and reselect the function
				hist.scrollToIndex(dp.length - 1);
				e.target.setSelection(0, fnText.text.length);
			}
		}

		// When the user clicks on a history item, populate the input fields
		// with its value and select the function text.
		function histChangeHandler(e:Event):void {
			stage.focus = fnText;
			fnText.text = hist.selectedItem.fnText;
			xText.text = hist.selectedItem.xText;
			yText.text = hist.selectedItem.yText;
			fnText.setSelection(0, fnText.text.length);
		}
		
		// Pop up the error panel with the given message. Sets the focus to the
		// text field in the panel so that a keypress will dismiss it.
		function showErrorPanel(err:String):void {
			errorPanel.msgText.text = err;
			errorPanel.visible = true;
			stage.focus = errorPanel.msgText;
		}
		
		// Hide the error panel.
		function closeBtnHandler(e:Event):void {
			stage.focus = fnText;
			errorPanel.visible = false;
		}
	}
}