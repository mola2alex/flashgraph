# Installation/Preparation #
Depending on how you want to use _flashgraph_, little or no installation may be needed.

There are two ways to use the grapher class. The easiest way it so use the component. This allows you to manipulate the grapher just like any other object on the stage--you can position it and see the live results of property changes in the Flash editor.

To install the Grapher2D component, copy the `Grapher2D.swc` file from the `components` directory to the following location, depending on your OS:
> Mac OS X:
> > `<home directory>/Library/Application Support/Adobe/Flash CS3/<language>/Configuration/Components`

> Windows:
> > `<home directory>\Local Settings\Application Data\Adobe\Flash CS3\en\Configuration\Components`

Then, from within Flash, the Grapher2D component should appear in the Components panel (`Window > Components`). If it doesn't, click the small down arrow in the upper right of the Components panel and select `Reload`.

The other option is to create a grapher "from scratch" in ActionScript. This has the benefit of not requiring an installation step, but doesn't allow easy manipulation of the object.

To use the expression parsing library or to create Grapher2D components in ActionScript, no real "installation" is needed. Flash just needs to be made aware of the location of the source code. To do this, in your Flash document, select File > Publish Settings. In the resulting window, select the "Flash" tab, and click "Settings..." button next to "ActionScript version." In that window, add the path to the directory containing the `mathlib` folder.  For Grapher2D, you also need to add the following path:

> `$(AppConfig)/Component Source/ActionScript 3.0/User Interface`

This last path is easy to forget; you may want to add it to your global classpath in Flash's general Preferences window, under the "ActionScript" section.


# Next Steps #

For basic examples of the expression parser and Grapher2D, see ExprExamples and GrapherExamples, respectively. More complex examples are included in the distribution in the `examples` directory.

The API documentation is available in the distribution in the `doc` directory, or online [here](http://flashgraph.googlecode.com/svn/trunk/doc/index.html). Note that the online version at that link is "bleeding edge" and may be out of sync with the packaged distribution.