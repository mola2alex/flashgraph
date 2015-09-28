# ASDoc? #
[ASDoc](http://labs.adobe.com/wiki/index.php/ASDoc) is Adobe's tool for generating HTML documentation from special inline ActionScript comments (much like [Javadoc](http://java.sun.com/j2se/javadoc/) and [Doxygen](http://www.stack.nl/~dimitri/doxygen/)). It is released as a part of the free [Flex SDK](http://labs.adobe.com/technologies/flex/sdk/) and runs on Windows, Linux, and Mac OSX.

The problem, however, is that ASDoc was written with Flex in mind, not Flash. In particular, ASDoc tries to run whatever source you give it through Flex's compiler. Since _flashgraph_ is not (yet?) intended for use in Flex, this causes some issues. Luckily, these are mainly of the linking variety and can be sidestepped with a few tricks.

# Details #

## The `fl` namespace ##
It's not all Flash code that causes issues. Pure, stand-alone ActionScript compiles just fine and generates no complaints from ASDoc. It's really just the `fl` namespace that causes issues as it's not part of the [packages included in Flex](http://livedocs.adobe.com/flex/201/langref/package-summary.html). When trying to run the Grapher2D component through ASDoc, for instance, I got errors along the line of "Error: The definition of base class UIComponent was not found." The solution is to squeeze the bits of the `fl` namespace you need into a SWC file and tell Flex to link it along with your code.

That sounds complicated. It isn't. In a new Flash document, make a new symbol called "fl-shim". Into this symbol, place a built-in component (I used a Button). Then, right-click on the symbol in the Library panel and choose "Export SWC File..." and save it somewhere as "fl-shim.swc".

Now that we have a nice package of our missing classes, we need to tell ASDoc about it. To do this, simply append `-library-path fl-shim.swc` to your `asdoc` command-line arguments. Things should work as expected.  If they didn't, make sure you've applied the [Flex 2.0.1 patch for Flash compatibility](http://kb.adobe.com/selfservice/viewContent.do?externalId=kb401493&sliceId=2) and try again.

## Other issues ##
Aside from the show-stopping linking issue, there are a number of small gotchas with the ASDoc/Flash combination.

### Built-in top-level Error classes ###
I often find myself reusing built-in exception classes like `ArgumentError` and `SyntaxError`. However, if you use the name of one of these in a `@throws` tag, ASDoc won't display any class for the exception in the HTML.  I haven't yet found a good way to fix this; I've just been writing painfully redundant code like below to include the exception class as part of the description:
```
@throws ArgumentError <code>ArgumentError</code>: Description here
```

### Spaces in filenames ###
On OSX (and presumably Linux) there is a bug in the `asdoc` shell script Adobe shipped in Flex 2.01 that breaks its compatibility with filenames containing spaces. To fix this, change the `$*` in the `java` command in `asdoc` to  `"$@"` (with the quotes). That is, change the line that reads
```
java $VMARGS -classpath "$FLEX_HOME/lib/asdoc.jar" flex2.tools.ASDoc +flexlib="$FLEX_HOME/frameworks" $*
```
to read
```
java $VMARGS -classpath "$FLEX_HOME/lib/asdoc.jar" flex2.tools.ASDoc +flexlib="$FLEX_HOME/frameworks" "$@"
```