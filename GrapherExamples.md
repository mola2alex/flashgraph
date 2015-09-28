# Introduction #
Flash has the ability to draw straight lines and bezier curves--beyond this, you're out of luck. That's where the `grapher` package comes in. In conjunction with the `expr` package for dynamic function evaluation, Flash is easily converted into an environment for interactive math applets.

## Setup ##
The heart of the grapher is the `Grapher2D` class. As explained on the GettingStarted page, there are two methods for using this class. It can be instantiated, positioned, and styled directly from code, or you can use the component version that allows design-time manipulation like any other Flash component.  In the examples in this tutorial, we will be using the component-based approach. For an example of a code-created `Grapher2D`, see the GrapherDemo in the `examples` folder.

Before proceeding, make sure you have followed the instructions on the GettingStarted page for installing the component and setting up the classpath in your Flash document (since we will be using the `expr` package as well).


# Basic Use #
Begin by dragging the `Grapher2D` component from Flash's Components panel (Window > Components). If it's not there, make sure you followed the instructions in GettingStarted, and try refreshing the panel by clicking the arrow in the upper right and selecting "Refresh".  Name the instance "grapher" and size it as you like.

Note all the properties you can change in the Parameters panel (Window > Properties > Parameters). For an explanation of each of these, see the [API documentation](http://flashgraph.googlecode.com/svn/trunk/doc/mathlib/grapher/Grapher2D.html). For now, let's just adjust the window range. Set the `xmin` property to -1 and note how the display in Flash automatically updates.

Once you're satisfied with the on-stage grapher preview, we'll turn to ActionScript to add some graphs. We'll create this example and the others on this page by entering some code in the `Actions` panel for the first frame of a new Flash document. First, we need to import the `grapher` package from the component:
```
import mathlib.grapher.*;
```

Now let's define the functions we want to draw. For now, we'll just write these in ActionScript. They must take one Number argument and return a Number.
```
function f(x:Number):Number {
    return Math.sin(2 * Math.PI * x);
}

function g(x:Number):Number {
    return 5 * Math.sin(Math.PI * x)
}
```

Next, let's make some [LineStyles](http://flashgraph.googlecode.com/svn/trunk/doc/mathlib/grapher/LineStyle.html) for our function graphs. These are simple wrappers of the options to `graphics.lineStyle` and take the same arguments:
```
var fLineStyle:LineStyle = new LineStyle(1, 0x00ff00);   // 1px green
var gLineStyle:LineStyle = new LineStyle(2, 0x0000ff);  // 2px blue
```

That's it for setup! We're now ready to graph `f` and `g`. To do this, we use the [addFnGraph() method](http://flashgraph.googlecode.com/svn/trunk/doc/mathlib/grapher/Grapher2D.html#addFnGraph()) of the grapher. This function returns a [FnGraph](http://flashgraph.googlecode.com/svn/trunk/doc/mathlib/grapher/FnGraph.html) object, but we're not interested in it at the moment.
```
grapher.addFnGraph(f, fLineStyle);
grapher.addFnGraph(g, gLineStyle);
```

Test the movie to see the results.

# Basic Use: Interaction #
The graphs we added with `addFnGraph()` are persistent; they will update with the graph as its window changes. To see this, let's add some basic keyboard interactivity with the graph. The code in this section is intended to come after that entered in the previous section.

Begin by adding an event listener for the grapher's keyboard events:
```
grapher.addEventListener(KeyboardEvent.KEY_DOWN, grapherKeyHandler);
```

Now when the users presses a key while the grapher has focus, the function `grapherKeyHandler` will be called. We'll implement it to adjust the window when arrow keys are pressed:
```
function grapherKeyHandler(e:KeyboardEvent):void {
    var nudgeAmount:Number = 0.5;  // Amount to shift the window by on keypress

    switch(e.keyCode) {
        case Keyboard.UP:
            grapher.setYRange(grapher.ymin + nudgeAmount, grapher.ymax + nudgeAmount);
        break;

        case Keyboard.DOWN:
            grapher.setYRange(grapher.ymin - nudgeAmount, grapher.ymax - nudgeAmount);
        break;

        case Keyboard.RIGHT:
            grapher.setXRange(grapher.xmin + nudgeAmount, grapher.xmax + nudgeAmount);
        break;

        case Keyboard.LEFT:
            grapher.setXRange(grapher.xmin - nudgeAmount, grapher.xmax - nudgeAmount);
        break;
    }
}
```

That's it. Test your movie again and try it out. If it doesn't seem to be responding, try clicking in the grapher first to make sure it has the keyboard focus.


# Combining with `expr` #
You should read the ExprExamples page before this section to get a feel for how the `expr` package works.

Astute readers may already have guessed how easy this is going to be. Recall that the `eval()` method of the [CompiledFn](http://flashgraph.googlecode.com/svn/trunk/doc/mathlib/expr/CompiledFn.html) class is the executable representation of a function. So, we can just do something like this (again assuming an instance of `Grapher2D` is on the stage and named `grapher`):
```
import mathlib.expr.*;
import mathlib.grapher.*; 

var env:Environment = new Environment("x");
var expr:String = "-3x^3 + 2x^2 - x + 1";
var fn:CompiledFn = Compiler.compile(env, expr);

grapher.addFnGraph(fn.eval);
```



# Next Steps #
The [API documentation](http://flashgraph.googlecode.com/svn/trunk/doc/mathlib/grapher/Grapher2D.html) covers all the methods and properties of `Grapher2D` and its cohorts. The GraphDemo example in the distribution contains a ton of keyboard and mouse interactions, and an example of using [PtGraphs](http://flashgraph.googlecode.com/svn/trunk/doc/mathlib/grapher/PtGraph.html). Also, the Magnify example in the `examples` directory of the distribution provides an interesting set of interactions for studying the concept of the derivative