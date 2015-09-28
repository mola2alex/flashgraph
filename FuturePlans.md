# Flex support #

# Grapher2D #
  * Value labels for tickmarks

  * Parametric graphs?
    * Shouldn't be bad to implement, and would certainly be interesting

  * Default keybindings?
    * Would cover zooming and nudging
    * How should the nudge value be expressed? A constant is no good. Maybe nths of the visible range?
    * Mouse-aided panning?

  * Mouse- and keyboard-manipulable graphs?
    * More example territory rather than built-in functionality
    * PtGraph and FnGraph are just Sprites underneath it all, so this is definitely doable.


# Expressions #
  * Easier route to default compilation
    * `Compiler.compile()` to take a list of variables?
    * ... or `Environment` to have `.compile()` and `.lex()` and `.parse()` as wrappers?
  * Clean up public properties
    * Most should be read-only, some shouldn't even be visible.