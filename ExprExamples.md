# Introduction #
The ability to graph functions is really no use if you can't easily allow the user to graph functions of their own definition. This is where the `mathlib.expr` package comes in: it is responsible for converting strings like "sin(2x)^2" into objects ActionScript can evaluate.

## Design ##
The `expr` package centers around the [Environment object](http://flashgraph.googlecode.com/svn/trunk/doc/mathlib/expr/Environment.html). This structure acts as a repository for all the valid functions, constants, operators and variables. It is responsible for associating strings like "sin" with the ActionScript function `Math.sin`.

Any use of the `expr` package will begin with the construction of an `Environment`. From there, however, there are a number of ways to proceed, depending on how much control you want over the process.

Before proceeding, make sure you have followed the instructions on the GettingStarted page for setting up the classpath in your Flash document.

# Basic Use: The `Compiler` #
The simplest way to convert a string to a callable ActionScript function is to use the `Compiler` class. The methods of `Compiler` are all static; you don't need to make an instance of the class to use it.

We'll create this example and the others on this page by entering some code in the `Actions` panel for the first frame of a new Flash document. First, we'll need to import the classes in the `expr` namespace:
```
import mathlib.expr.*;
```

Now we'll make an `Environment`. The arguments to `Environment`'s constructor are a list of valid variable names. We're going to create a function of two variables, `x` and `y`, so we make the Environment like this:
```
var env:Environment = new Environment("x", "y");
```

If we had wanted a function of no variables (i.e., just an expression), we could have written `Environment()`, without any arguments. Valid variable names with a begin with a letter or an underscore and then contain some number of letters, numbers, or underscores. See the documentation of [Environment's constructor](http://flashgraph.googlecode.com/svn/trunk/doc/mathlib/expr/Environment.html#Environment()) for further details.

Believe it or not, we're now ready to parse an expression. The callable object returned from `Compiler`'s methods is a [CompiledFn](http://flashgraph.googlecode.com/svn/trunk/doc/mathlib/expr/CompiledFn.html), so we use a variable of that type to store the result:
```
var fn:CompiledFn = Compiler.compile(env, "2x^y");
```

To evaluate a `CompiledFn`, call its `eval()` method with the `Number` values of the independent variables. These are specified in the same order as they were given to the `Environment` you used in the call to `compile()`. So, to evaluate `fn` at `x` = 2 and `y` = 3 and print the result to the debug window, write the following code:
```
trace(fn.eval(2, 3));  // Prints 16
```

That's all there is to the most basic use, which should be enough for most purposes. For a complete rundown of the valid functions, constants, and operators in a default `Environment`, see the document for its [constructor](http://flashgraph.googlecode.com/svn/trunk/doc/mathlib/expr/Environment.html#Environment()).

Continue reading to see how to handle parse errors, add elements to an `Environment`, or take a more explicit approach to compilation.

# Interlude: Error Handling #
As noted in the [documentation](http://flashgraph.googlecode.com/svn/trunk/doc/mathlib/expr/Compiler.html#compile()), the `Compiler.compile()` method throws a `SyntaxError` if the string could not be parsed. The `message` member of this exception contains a (hopefully) helpful diagnosis of the problem. Using `try...catch`, errors can be caught and brought to the attention of the user, like in the example below:
```
import mathlib.expr.*;
var env:Environment = new Environment("x");

try {
    var fn:CompiledFn = Compiler.compile(env, "2xy");
    trace(fn.eval(5));
} catch(err:SyntaxError) {
    trace("Error parsing function: " + err.message);  // Prints "Error parsing function: unknown identifier y"
}
```


# Intermediate Use: Modifying an `Environment` #
As was said previously, the `Environment` encapsulate information about the valid elements in an expression. In the previous example, we just used the stock `Environment` with no modifications. In this example we will add a new operator and function.

Begin as before, importing and making an `Environment`:
```
import mathlib.expr.*;
var env:Environment = new Environment("x", "y");
```

Now we will write the ActionScript functions that will correspond to our operator. An operator in the `expr` package is represented as a binary function: for example, the string "x + y" gets translated to `add(x, y)` (where `add` is just a function that uses the built in `+` operator). So, let's add an operator `%` that does modular reduction like the eponymous operator in ActionScript. Since the operator is not a function, we can't pass it along to `Environment` directly; we must wrap it in a function. The implementing function must take two `Number` arguments and return a `Number`:

```
function modOp(x:Number, y:Number):Number {
    return x % y;
}
```

Now we add it to the `Environment`. Operators in `expr` come in two flavors: those that have the precedence of addition, and those that have the precedence of multiplication. Most users will probably use parentheses if they're unsure of the order of operation, but we'll add our new `%` operator on the multiplication level using the [addMulOp() method](http://flashgraph.googlecode.com/svn/trunk/doc/mathlib/expr/Environment.html#addMulOp()):
```
env.addMulOp("%", modOp);
```

Adding a function is similar: simply define it in ActionScript and add it to an `Environment` with the [addFn() method](http://flashgraph.googlecode.com/svn/trunk/doc/mathlib/expr/Environment.html#addFn()):
```
function add3(x:Number, y:Number, z:Number):Number {
    return x + y + z;
}

env.addFn("add3", add3);
```

Now we can write an expression with our new operator and function and compile and evaluate it as before:
```
var fn:CompiledFn = Compiler.compile("add3(x % 2, x % 4, y)")
trace(fn.eval(6, 5));  // Prints 7
```

See the documentation for [Environment](http://flashgraph.googlecode.com/svn/trunk/doc/mathlib/expr/Environment.html) for more customizations you can make.


# Advanced Use: `Lexer`, `Parser` and `Compiler` #
This section is really only of use to masochists or those intimately interested in the guts of the `expr` package.

The `Compiler.compile()` method we have been using thus far is really just a wrapper over a three-step process: lex (tokenize), parse, and compile.  The [Lexer.lex() method](http://flashgraph.googlecode.com/svn/trunk/doc/mathlib/expr/Lexer.html#lex()) is responsible for converting the string into an `Array` of [Tokens](http://flashgraph.googlecode.com/svn/trunk/doc/mathlib/expr/datatype/Token.html). A token is a representation of a known element of the `Environment` (like a function name) or of the basic "language" understood by the `Parser` (like a parenthesis or a comma). The lexer also handles the rules for implicit multiplication by inserting a multiplication operator token where appropriate.

From there, the [Parser.parse() method](http://flashgraph.googlecode.com/svn/trunk/doc/mathlib/expr/Parser.html#parse()) attempts to assign meaning to the flat `Token` array by applying rules of the grammar to generate a [ParseTree](http://flashgraph.googlecode.com/svn/trunk/doc/mathlib/expr/datatype/ParseTree.html). This converts things like "x + y" into a tree with `+` at the root and `x` and `y` as children.

The last step is to convert the `ParseTree` into a more usable form. This is done by the [Compiler.compileParseTree()](http://flashgraph.googlecode.com/svn/trunk/doc/mathlib/expr/Compiler.html#compileParseTree()) method, which does a simple prefix walk of the ParseTree, accumulating the results in a new `CompiledFn`.  See [the Wikipedia page on Polish Notation](http://en.wikipedia.org/wiki/Polish_notation) for why we'd want to do this.

If the `optimize` parameter to `compileParseTree()` is true, the compiler takes the extra step of collapsing constant subtrees to their numeric values. For instance, if the string "max(15 `*` 2 + 22, x)" was given, the optimizing step would convert "15 `*` 2 + 22" to 52. This saves time when re-evaluating the compiled function.

Finally, when `CompiledFn.eval()` is called, it substitutes values for the independent variables in the `Environment` and evaluates its [prefixArray](http://flashgraph.googlecode.com/svn/trunk/doc/mathlib/expr/CompiledFn.html#prefixArray) member, which can be done quickly thanks to Polish notation.

We decided to take this approach because the main goal for the `expr` package is to plug its results into a grapher, which needs to evaluate the the function many times in succession. Caching the result of the parse tree traversal makes this as quick as possible.

Here's an example of the complete process with no shortcuts. The datatypes in `mathlib.expr.datatype` have rudimentary `toString()` methods, so you can see some version of the output of the steps along the way.
```
import mathlib.expr.*;
import mathlib.expr.datatype.*;

var expr:String = "max(x, 22 + 5)";

var env:Environment = new Environment("x");

var tokArr:Array = Lexer.lex(env, expr);
trace("Tokens: " + tokArr.toString());
// Tokens: [function],[(],[variable:[var_0]],[,],[number:22],[addition operator],[number:5],[)]

var pt:ParseTree = Parser.parse(tokArr);
trace("Parse tree: " + pt.toString());
// Parse tree: ([function]([variable:[var_0]])([addition operator]([number:22])([number:5])))
// This is in a Lisp-like notation for trees. Here's some ASCII art:
//     function (max)
//       |- var_0 (x)
//       `- addition operator (+)
//          |- 22
//          `-  5

var fn:CompiledFn = Compiler.compileParseTree(pt);
trace("Prefix traversal: " + fn.prefixArray.toString());
// Prefix traversal: function Function() {},[var_0],27
// Note the 22 + 5 has been collapsed to a literal 27.

trace("f(5) = " + fn.eval(5).toString());
// f(5) = 27
```