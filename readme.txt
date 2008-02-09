flashgraph

http://flashgraph.googlecode.com
tim.clem@gmail.com

=========================

flashgraph consists of a set of ActionScript 3 components and classes to facilitate mathematics in Flash CS3. This document covers basic installation and how to get started. For more in-depth examples, see the tutorials on the wiki (http://code.google.com/p/flashgraph/w/list) and the files in the "examples" directory.


Installation / Preparation
--------------------------
There are two ways to use the grapher class. The easiest way it so use the component. This allows you to manipulate the grapher just like any other object on the stage--you can position it and see the live results of property changes in the Flash editor.

The other option is to create a grapher "from scratch" in ActionScript. This has the benefit of not requiring an installation step, but doesn't allow easy manipulation of the object.


To install the Grapher2D component, copy the Grapher2D.swc file from the "components" directory to the following location, depending on your OS:
   Mac OS X:
       <home directory>/Library/Application Support/Adobe/Flash CS3/<language>/Configuration/Components
   Windows:
       <home directory>\Local Settings\Application Data\Adobe\Flash CS3\en\Configuration\Components

Then, from within Flash, the Grapher2D component should appear in the Components panel (Window > Components). If it doesn't, click the small down arrow in the upper right of the Components panel and select "Reload."


To use the expression parsing library or to create Grapher2D components in ActionScript, no real "installation" is needed. Flash just needs to be made aware of the location of the source code. To do this, open a new Flash document, and select File > Publish Settings. In the resulting window, select the "Flash" tab, and click the "Settings..." button next to "ActionScript version." In that window, add the path to the directory containing the "mathlib" folder.  For Grapher2D, you also need to add the following path:
    $(AppConfig)/Component Source/ActionScript 3.0/User Interface

This path is easy to forget; you may want to add it to your global classpath in Flash's general Preferences window.


Simple Examples
---------------
These are extremely basic, "getting started" kinds of things. For more detail, see the "Next Steps" section.

Expression parsing:
Once the mathlib packages are in your classpath (see above), simply import the "expr" package to begin using the library. For example, try the following in the first frame of a new file:

    import mathlib.expr.*;

    var env:Environment = new Environment("x");
    var cmpFn:CompiledFn = Compiler.compile(env, "xsin(x)^2");
    trace(cmpFn.eval(Math.PI));


Graphing:
To use the grapher from ActionScript, add the following code to the first frame of a new file:

    import mathlib.grapher.*;
    
    var grapher:Grapher2D = new Grapher2D();
    grapher.width = 400;
    grapher.height = 400;
    addChild(grapher);

Or, if using the component, just add a new one to the stage and give the instance the name "grapher." Then, add the following code to graph the function f:

    function f(x:Number):Number {
        return Math.abs(Math.pow(x, 3)) + Math.sin(x);
    }

    grapher.addFnGraph(f);


Combination:
Astute readers may now be able to see how easy it would be to begin parsing user-given functions. Here's an example of feeding the expression parsing functionality into the grapher:

	import mathlib.grapher.*;
	import mathlib.expr.*;
	
	var grapher:Grapher2D = new Grapher2D();
	grapher.width = 400;
	grapher.height = 400;	
	addChild(grapher);
	
	var env:Environment = new Environment("x");
	var fn:String = "1/sin(x)^2";
	var cmpFn:CompiledFn = Compiler.compile(env, fn);
	
	grapher.addFnGraph(cmpFn.eval);


Next Steps
----------
Details on the classes and APIs is available in the "doc" directory or online at http://flashgraph.googlecode.com/svn/trunk/doc/index.html. There are several well-commented examples in the "examples" directory and more basic tutorials on the wiki (http://code.google.com/p/flashgraph/w/list).

If you run into issues or find a bug, don't hesitate to send me an email or make a note on the Google Code page (http://flashgraph.googlecode.com).