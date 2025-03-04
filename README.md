# Assignment 4: Nano (270 points)

## Overview

The overall objective of this assignment is to
fully understand the notions of

* lexing,
* parsing,
* scoping,
* binding,
* environments and closures,

by implementing an interpreter for a subset of Haskell.

No individual function requires more than 15-25
lines, so if you're answer is longer, you can be sure
that you need to rethink your solution.

The assignment is in the files:

1. [Lexer.x](/src/Language/Nano/Lexer.x)
2. [Parser.y](/src/Language/Nano/Parser.y)
3. [Eval.hs](/src/Language/Nano/Eval.hs)

and

+ [tests/Test.hs](/tests/Test.hs) has some sample tests,
  and testing code that you will use to check your
  assignments before submitting.

You should only need to modify the parts of the files which say:

```haskell
error "TBD: ..."
```

with suitable Haskell implementations.

---
**Note:** Start early! Lexing and Parsing are new tools, which may
take a while to grok.

---


## Assignment Testing and Evaluation

Your functions/programs **must** compile and run on `ieng6.ucsd.edu`.

Most of the points, will be awarded automatically, by
**evaluating your functions against a given test suite**.

[Tests.hs](/tests/Test.hs) contains a very small suite
of tests which gives you a flavor of of these tests.
When you run

```shell
$ stack test
```

Your last lines should have

```
All N tests passed (...)
OVERALL SCORE = ... / ...
```

**or**

```
K out of N tests failed
OVERALL SCORE = ... / ...
```

**If your output does not have one of the above your code will receive a zero**

If for some problem, you cannot get the code to compile,
leave it as is with the `error ...` with your partial
solution enclosed below as a comment.

The other lines will give you a readout for each test.
You are encouraged to try to understand the testing code,
but you will not be graded on this.

## Submission Instructions

To submit your code, just do:

```bash
$ make turnin
```

## Data Structures and Overview

In this assignment, you will build an interpreter
for a subset of Haskell called *Nano*. The following
data types (in `Types.hs`) are used to represent the
different elements of the language.

### Binary Operators

Nano uses the following **binary** operators encoded
within the interpreter as values of type `Binop`.

```haskell
data Binop
  = Plus
  | Minus
  | Mul
  | Div
  | Eq
  | Ne
  | Lt
  | Le
  | And
  | Or
  | Cons
```

### Expressions

All Nano programs correspond to **expressions**
each of which will be represented within your
interpreter by Haskell values of type `Expr`.

```haskell
data Expr
  = EInt  Int
  | EBool Bool
  | ENil
  | EVar Id
  | EBin Binop Expr Expr
  | EIf  Expr Expr  Expr
  | ELet Id   Expr  Expr
  | EApp Expr Expr
  | ELam Id   Expr
  deriving (Eq)
```

where `Id` is just a type alias for `String` used to represent
variable names:

```haskell
type Id = String
```

The following lists some Nano expressions,
and the value of type `Expr` used to represent
the expression inside your interpreter.

1. Let-bindings

```haskell
let x = 3 in x + x
```

is represented by

```haskell
ELet "x" (EInt 3)
  (EBin Plus (EVar "x") (EVar "x"))
```

2. Anonymous Functions definitions

```haskell
\x -> x + 1
```

is represented by

```haskell
ELam "x" (EBin Plus (EVar "x") (EInt 1))
```

3. Function applications ("calls")

```haskell
f x
```

is represented by

```haskell
EApp (EVar "f") (EVar "x")
```

4. (Recursive) Named Functions

```haskell
let f = \ x -> f x in
  f 5
```

is represented by

```haskell
ELet "f" (ELam "x" (EApp (EVar "f") (EVar "x")))
  (EApp (Var "f") (EInt 5))
```


### Values

We will represent Nano **values**, i.e. the results
of evaluation, using the following datatype

```haskell
data Value
  = VInt  Int
  | VBool Bool
  | VClos Env Id Expr
  | VNil
  | VPair Value Value
  | VPrim (Value -> Value)
```

where an `Env` is simply a dictionary: a list of pairs
of variable names and the values they are bound to:

```haskell
type Env = [(Id, Value)]
```

Intuitively, the Nano integer value `4` and boolean value
`True` are represented respectively as `VInt 4` and `VBool True`.
The more interesting case is for closures that correspond to
function values (see [lecture notes](https://ucsd-cse130.github.io/wi20/lectures/05-closure.html)).

- `VClos env "x" e` represents a function with argument `"x"`
   and body-expression `e` that was defined in an environment
   `env`.

## Problem 1: Nano Interpreter (Eval.hs)

In this problem, you will implement an interpreter for Nano.

### (a) 25 points


First consider the (restricted subsets of) types described below:

```haskell
data Binop = Plus | Minus | Mul

data Expr  = EInt Int
           | EVar Id
           | EBin Binop Expr Expr

data Value = VInt Int
```

That is,

- An *expression* is either an `Int` constant,
  a variable, or a binary operator applied
  to two sub-expressions.

- A *value* is an integer, and an *environment*
  is a list of pairs of variable names and values.

Write a Haskell function

```haskell
lookupId :: Id -> Env -> Value
```

where `lookupId x env` returns the most recent
binding for the variable `x` (i.e. the first from the left)
in the list representing the environment.
If no such value is found, you should throw an error:

```haskell
throw (Error ("unbound variable: " ++ x))
```

When you are done you should get the following behavior:

```haskell
>>> lookupId "z1" env0
0

>>> lookupId "x" env0
1

>>> lookupId "y" env0
2

>>> lookupId "mickey" env0
*** Exception: Error {errMsg = "unbound variable: mickey"}
```

Next, use `lookupId` to write a function

```haskell
eval :: Env -> Expr -> Value
```

such that `eval env e` evaluates the Nano
expression `e` in the environment `env`
(i.e. uses `env` for the values of the
**free variables** in `e`), and throws
an `Error "unbound variable"` if the
expression contains a free variable
that is **not bound** in `env`.

Once you have implemented this functionality and
recompiled, you should get the following behavior:

```haskell
>>> eval env0 (EBin Minus (EBin Plus "x" "y") (EBin Plus "z" "z1"))
0

>>> eval env0 "p"
*** Exception: Error {errMsg = "unbound variable: p"}
```

### (b) 20 points

Next, add support for the binary operators

```haskell
data Binop = ...
           | Eq | Ne | Lt | Le | And | Or
```

This will require using the new value type `Bool`

```haskell
data Value = ...
           | VBool Bool
```

* The operators `Eq` and `Ne` should work if both operands
  are `VInt` values, or if both operands are `VBool` values.

* The operators `Lt` and `Le` are only defined for `VInt`
  values, and `&&` and `||` are only defined for `VBool`
  values.

* Other pairs of arguments are **invalid** and you should
  throw a suitable error.

```haskell
throw (Error "type error")
```

When you are done, you should see the following behavior

```haskell
>>> eval []  (EBin Le (EInt 2) (EInt 3))
True

>>> eval []  (EBin Eq (EInt 2) (EInt 3))
False

>>> eval []  (EBin Lt (EInt 2) (EBool True))
*** Exception: Error {errMsg = "type error: binop"}
```

Also note that, so long as you error message is appropriate, you will receive
points. We will not be checking for an exact error message. However,
it should contain the substring 'type error:'.

Next, implement the evaluation of `EIf p t f` expressions.

1. First, evaluate the `p`; if `p` does not evaluate to a
   `VBool` value, then your evaluator should
   `throw (Error "type error")`,

2. If `p` evaluates to the true value then the expression
   `t` should be evaluated and returned as the value of
   the entire `If` expression,

3. Instead, if `p` evaluates to the false value, then `f`
   should be evaluated and that result should be returned.

Once you have implemented this functionality,
you should get the following behavior:

```haskell
>>> let e1 = EIf (EBin Lt "z1" "x") (EBin Ne "y" "z") (EBool False)
>>> eval env0 e1
True

>>> let e2 = EIf (EBin Eq "z1" "x") (EBin Le "y" "z") (EBin Le "z" "y")
>>> eval env0 e2
False
```

### (c) 25 points

Now consider the extended the types as shown below which includes
the *let-in* expressions which introduce local bindings.

```haskell
data Expr
  = ...
  | ELet Id   Expr  Expr
```

The expression `ELet x e1 e2` should be evaluated
as the Haskell expression `let x = e1 in e2`.

Once you have implemented this functionality and
recompiled, you should get the following behavior:

```haskell
>>> let e1 = EBin Plus "x" "y"
>>> let e2 = ELet "x" (EInt 1) (ELet "y" (EInt 2) e1)
>>> eval [] e2
3
```

### (d)  25 points

Next, extend the evaluator so it includes the expressions
corresponding to function definitions and applications.

```haskell
data Expr
  = ...
	| ELam Id   Expr
	| EApp Expr Expr
```

In the above,

* `ELam x e` corresponds to the function defined `\x -> e`, and

* `EApp e1 e2` corresponds to the Haskell expression `e1 e2`
   (i.e. applying the argument `e2` to the function `e1`).

To evaluate functions, you will need to extend the set of
values yielded by your evaluator to include closures.

```haskell
data Value
  = ...
	| VClos Env Id Expr
```

For now, assume the functions *are not recursive*.

However, functions do have values represented by
the `VClos env x e` where

* `env` is the environment at the point where
   that function was declared,
* `x` is the formal parameter, and
* `e` the body expression of the function.

Extend your implementation of `eval` by adding the
appropriate cases for the new type constructors.
Once you have implemented this functionality and
recompiled, you should get the following behavior:

```haskell
>>> eval [] (EApp (ELam "x" (EBin Plus "x" "x")) (EInt 3))
6

>>> let e3 = ELet "h" (ELam "y" (EBin Plus "x" "y")) (EApp "f" "h")
>>> let e2 = ELet "x" (EInt 100) e3
>>> let e1 = ELet "f" (ELam "g" (ELet "x" (EInt 0) (EApp "g" (EInt 2)))) e2
>>> eval [] e1
102
```

### (e) 30 points

Make the above work for recursively defined functions.
Once you have implemented this functionality, you should
get the following behavior:

```haskell
-- >>> :{
-- eval [] (ELet "fac" (ELam "n" (EIf (EBin Eq "n" (EInt 0))
--                                  (EInt 1)
--                                  (EBin Mul "n" (EApp "fac" (EBin Minus "n" (EInt 1))))))
--             (EApp "fac" (EInt 10)))
-- :}
-- 3628800
```


### (f) 40 points

Finally, extend your program to support operations on lists.

```haskell
data Binop = ...
           | Cons

data Expr = ...
          | ENil

data Value = ...
           | VNil
           | VPair Value Value
```

In addition to the changes to the data types, add support
for two functions `head` and `tail` which do what the
corresponding Haskell functions do. Once you have implemented
this functionality and recompiled, you should get the
following behavior

```haskell
>>> let el = EBin Cons (EInt 1) (EBin Cons (EInt 2) ENil)

>>> execExpr el
(1 : (2 : []))

>>> execExpr (EApp "head" el)
1

>>> execExpr (EApp "tail" el)
(2 : [])
```
The constructor `VPrim` will come in handy here.

## Problem 2: Nano Lexer (Lexer.x) and Parser (Parser.y)

The goal of this problem is to write a **lexer** and **parser**
for Nano using the tools `Alex` and `Happy`. (Google those terms
for more information about them.) In each subproblem, we will
increase the complexity of the expressions parsed by your
implementation.

### (a) 15 points

We will begin by making our parser recognize some of
the simplest Nano expressions: constants and variables.

Begin with `Lexer.x` using the given rules for
keywords `in` and `&&` as an inspiration, fill in the
rules for

* `TRUE` and `FALSE` which should correspond to
   the string literals `True` and `False`.

* `ID` which has a single `String` argument,
  which holds the name of the variable (identifier)
  represented by the token. An identifier is a
  letter (capital or lowercase) followed by
  zero or more letters or digits.

* `NUM` which has a single `Int` argument,
   which holds the value of the numeric literal,
   which corresponds to a sequence of one or more digits.
---
**Note**
Be careful when implementing the regular expressions for in `Lexer.x`,
as an incorrect expression can cause your program to leak memory
pretty quickly. You'll want to either watch your memory usage and be
ready to kill the test, or use a memory limiting tool like this one:
[timeout](https://github.com/pshved/timeout).

---

Once you have implemented this functionality, you should get the
following behavior:

```haskell
>>> parseTokens "True"
Right [TRUE (AlexPn 0 1 1)]

>>> parseTokens "True False 12345 foo bar baz"
Right [TRUE (AlexPn 0 1 1),FALSE (AlexPn 5 1 6),NUM (AlexPn 11 1 12) 12345,ID (AlexPn 17 1 18) "foo",ID (AlexPn 21 1 22) "bar",ID (AlexPn 25 1 26) "baz"]
```

The `AlexPn n l c` denote the **position**
in the string where the token was parsed.
For example, the `FALSE` is at character
`5`, line `1` and column `6`.

Now proceed to `Parser.y`.

Add rules to the parser so that `True`, `False`,
integers, and identifiers are parsed into suitable
`Expr` values.

Once you have implemented this functionality,
you should get the following behavior:

```haskell
>>> parse "True"
EBool True

>>> parse "False"
EBool False

>>> parse "123"
EInt 123

>>> parse "foo"
EVar "foo"
```

### (b) 15 points

Add the following tokens to the lexer and parser.

| String  | Token   |
|:--------|:--------|
| `let`   | `LET`   |
| `=`     | `EQB`   |
| `\`     | `LAM`   |
| `->`    | `ARROW` |
| `if`    | `IF`    |
| `then`  | `THEN`  |
| `else`  | `ELSE`  |


These should be parsed to `ELet`, `ELam`, and `EIf`
expressions, that is,

- a **let** expression should have the form `let <id> = <expr> in <expr>`,
  or the form `let <id> <ids> = <expr> in <expr>`,
- a **function** expression should have the form `\ <id> -> <expr>` and
- an **if** expression should be `if <expr> then <expr> else <expr>`.

Here `<id>` denotes any identifier from part (a),
`<ids>` denotes a sequence of one or many space-separated `<id>`s,
and `<expr>` denotes any expression from part (a),
or any let / fun / if expression.

---
**Note**

The order of rules in your lexer definitions matters: earlier patterns
will match first, then later patters, much like the function cases in
Haskell.

---
Once you have implemented this functionality
you should get the following behavior prompt:

```haskell
>>> parseTokens "let foo = \\x -> if y then z else w in foo"

Right [LET (AlexPn 0 1 1),ID (AlexPn 4 1 5) "foo",EQB (AlexPn 8 1 9),
       LAM (AlexPn 10 1 11),ID (AlexPn 11 1 12) "x",ARROW (AlexPn 13 1 14),
       IF (AlexPn 16 1 17),ID (AlexPn 19 1 20) "y",THEN (AlexPn 21 1 22),
       ID (AlexPn 26 1 27) "z",ELSE (AlexPn 28 1 29),ID (AlexPn 33 1 34) "w",
       IN (AlexPn 35 1 36),ID (AlexPn 38 1 39) "foo"]

>>> parse "let foo = \\x -> if y then z else w in foo"
ELet "foo" (ELam "x" (EIf (EVar "y") (EVar "z") (EVar "w"))) (EVar "foo")

>>> parse "let foo x = if y then z else w in foo"
ELet "foo" (ELam "x" (EIf (EVar "y") (EVar "z") (EVar "w"))) (EVar "foo")
```

### (c) 15 points

Add the following tokens to the lexer and parser.

| String  | Token   |
|:--------|:--------|
| `+`     | `PLUS`  |
| `-`     | `MINUS` |
| `*`     | `MUL`   |
| `<`     | `LESS`  |
| `<=`    | `LEQ`   |
| `==`    | `EQL`   |
| `/=`    | `NEQ`   |
| `\|\|`  | `OR`    |


Add all of these as binary operators to your parser.
Each should result in a `EBin` expression with
the corresponding `binop`.  The arguments to
these binary operators may be *any* expressions.
(You don't need to worry about types:  `3 + True || 7`
is allowed as far as the parser is concerned.)

Once you have implemented this functionality and
recompiled, you should get the following behavior:

```haskell
>>> parseTokens "+ - * || < <= = && /="
Right [PLUS (AlexPn 0 1 1),MINUS (AlexPn 2 1 3),
       MUL (AlexPn 4 1 5),OR (AlexPn 6 1 7),
       LESS (AlexPn 9 1 10),LEQ (AlexPn 11 1 12),
       EQB (AlexPn 14 1 15),AND (AlexPn 16 1 17),
       NEQ (AlexPn 19 1 20)]

>>> parse "x + y"
EBin Plus (EVar "x") (EVar "y")

>>> parse "if x <= 4 then a || b else a && b"
EIf (EBin Le (EVar "x") (EInt 4)) (EBin Or (EVar "a") (EVar "b")) (EBin And (EVar "a") (EVar "b"))

>>> parse "if 4 <= z then 1 - z else 4 * z"
EIf (EBin Le (EInt 4) (EVar "z")) (EBin Minus (EInt 1) (EVar "z")) (EBin Mul (EInt 4) (EVar "z"))

>>> parse "let a = 6 * 2 in a /= 11"
ELet "a" (EBin Mul (EInt 6) (EInt 2)) (EBin Ne (EVar "a") (EInt 11))
```

### (d) 10 points

Add rules to your parser to allow parenthesized expressions.
In addition, add a rule to your parser for function application.
Recall that function application is simply `"<expr> <expr>"`
which corresponds to calling the (function corresponding to the)
left expression with the (argument corresponding to the)
right expression.

Once you have implemented this functionality and recompiled,
you should get the following behavior:


```haskell
>>> parseTokens "() (  )"
Right [LPAREN (AlexPn 0 1 1),RPAREN (AlexPn 1 1 2),LPAREN (AlexPn 3 1 4),RPAREN (AlexPn 6 1 7)]

>>> parse "f x"
EApp (EVar "f") (EVar "x")

>>> parse "(\\ x -> x + x) (3 * 3)"
EApp (ELam "x" (EBin Plus (EVar "x") (EVar "x"))) (EBin Mul (EInt 3) (EInt 3))

>>> parse "(((add3 (x)) y) z)"
EApp (EApp (EApp (EVar "add3") (EVar "x")) (EVar "y")) (EVar "z")

>>> parse <$> readFile "tests/input/t1.hs"
EBin Mul (EBin Plus (EInt 2) (EInt 3)) (EBin Plus (EInt 4) (EInt 5))

>>> parse <$> readFile "tests/input/t2.hs"
ELet "z" (EInt 3) (ELet "y" (EInt 2) (ELet "x" (EInt 1) (ELet "z1" (EInt 0) (EBin Minus (EBin Plus (EVar "x") (EVar "y")) (EBin Plus (EVar "z") (EVar "z1"))))))

```

### (e) 35 points

Restructure your parser to give binary operators the following
precedence and associativity.  This will likely require that you both
add additional rules to your parser and use
[Happy's precedence syntax](https://www.haskell.org/happy/doc/html/sec-Precedences.html)


**Operators Precedence Order**

+ (Highest) Fun Application
+ `*`
+ `+`, `-`
+ `==`, `/=`, `<`, `<=`
+ `&&`
+ (Lowest) `||`

**Precedence** Function application having higher precedence than
multiplications, and multiplication higher than addition
means that `"1+f x*3"` should be parsed as if it were
`"1+((f x)*3)"`.

**Associativity** All Operators are *Left associative*
means that `"1-2-3-4"` should be parsed as if it were
`"((1-2)-3)-4"`, and `"f x y z"` should be parsed as
if it were `"((f x) y) z"`.

Once you have implemented this functionality and recompiled,
you should get the following behavior:

```haskell
>>> parse "1-2-3"
EBin Minus (EBin Minus (EInt 1) (EInt 2)) (EInt 3)
>>> parse "1+a&&b||c+d*e-f-g x"
EBin Or (EBin And (EBin Plus (EInt 1) (EVar "a")) (EVar "b")) (EBin Minus (EBin Minus (EBin Plus (EVar "c") (EBin Mul (EVar "d") (EVar "e"))) (EVar "f")) (EApp (EVar "g") (EVar "x")))
```

### (f) 15 points

Add the following tokens to the lexer


| String | Token   |
|:-------|:--------|
| `[`    | `LBRAC` |
| `]`    | `RBRAC` |

Add rules to your parser to support parsing lists.
`"[a,b,c]"` should be parsed as if it were
`"((a):(b):(c):[])"`. The `:` operator should
have higher priority than the comparison
functions (`==`, `<=` etc.), and lower priority
than `+` and `-`.
In addition, `:` should be right associative.  `"[]"`
should be parsed as `ENil`, and `:` should be treated
as any other binary operator.

Also, implement equality for lists in `Eval.hs`.

Once you have implemented this functionality you should get
the following behavior

```haskell
>>> parse "1:3:5:[]"
EBin Cons (EInt 1) (EBin Cons (EInt 3) (EBin Cons (EInt 5) ENil))

>>> parse "[1,3,5]"
EBin Cons (EInt 1) (EBin Cons (EInt 3) (EBin Cons (EInt 5) ENil))
```

## Debugging Hw4 : Notes by Aidan Denlinger

HW4 can get a bit tricky in terms of how you can test and run programs. Here’s a quick document on what to use for debugging each part of your Nano implementation. The README also covers this information, so this document isn’t necessary, but hopefully it’s a good reference!

### What the Public Test Suite is Running

_You should test your functions with `make ghci` rather than adding to the test suite (`ghci` is much easier to interact with)._ However, it can be useful to know what commands the public test suite is running to see why your function is not passing a test, so here’s a breakdown of how the test suite works:

Each PA has a file named `Test.hs` in the `tests` folder. This contains the test suite. Here’s how normal tests are broken down, using a test from HW4 as an example (comments added by us):

```haskell
    scoreTest ( Nano.eval env1  -- The function being called
              , Nano.EVar "c1"  -- The parameter
              , Nano.VInt 1     -- The expected result
              , 2               -- The number of points the test is worth
              , "1a - c1")      -- Name of the test
```

So, this test is named “1a - c1”, it runs `eval env1 EVar "c1"` and to pass the test your function must return `VInt 1`. `env1` and `env2` are defined at the bottom of `Test.hs`.

Some notes on actually running this test in `make ghci`: You can remove the `Nano.` in front of everything when you’re in `ghci`, since `ghci` automatically imports `Nano` (which is the PA). Specifically for the `env1/env2` tests, since env1 and env2 are defined in the test suite, they aren’t imported into `ghci`. If you want to run these tests inside of `ghci`, you may want to copy over the lines that define `env1` and `env2` from the bottom of `Test.hs` to the bottom of `Eval.hs`, which will import them into the PA/ghci.

Once again, you don’t need to write your own tests, just use this to understand what the test cases are and test your functions yourself in `make ghci`. Also keep in mind that the public test suite doesn’t check everything and there will be hidden tests - be sure to check corner cases on your own!

### Debugging Part 1

See @407 if `make ghci` doesn’t load your PA and you cloned the repo in the first few hours! See @486 if any command fails because of a `createDirectory` error and you cloned the repo on Tuesday or later!

If `make ghci` cannot find `Language.Nano.Parser` or `Language.Nano.Lexer`, run `make test` once then try `make ghci`. `Lexer.x` and `Parser.y` get generated into `.hs` files (more on that in part 2), but they need to be generated at least once or ghci will refuse to work. Running the suite once will generate those files.

As shown in the README, `eval` takes in an `Env` and an `Expr` and returns the output. This should be all you need to test Part 1 in `make ghci` or with the inline tests.

### Debugging Part 2

If you’re making changes in your lexer and parser, but those changes aren’t getting reflected in `make ghci`, try running `make test` then `make ghci`\- `make test` ensures your lexer and parser are regenerated.

Part 2 has a lot of moving parts. The README covers these debugging functions, but here’s everything in one list to help you with debugging. Go in order here - start with `parseTokens`, and when you’re confident your lexer works, then test with `parse` to test the parser, and then finally use `execString` to check the evaluator. You run these functions in `make ghci`:

*   `parseTokens` will run a string through the lexer and return the Tokens.
*   `parse` will run a string through the lexer, _then_ through the parser and return the Expr. (So be sure to test your lexer first with `parseTokens`!)
*   `execString` will run a string through the lexer, _then_ the parser, _then_ the evaluator from Part 1, and return the Value.

### Debugging the File Tests/Writing Your Own File Tests

These are the last tests you should work on. These tests take in files as input, and run it through the lexer, parser, and evaluator.

**Copy pasting the contents of a file into ghci will run it as a HASKELL program and won’t use your lexer, parser, or evaluator! To run a file through _your_ Nano implementation, you want to use `execFile`. See below for information on that and more functions.**

*   the files themselves are in `tests/input`. In `tests/Test.hs`, the `fileTests` list the file, the expected answer, and the point value in the test suite.
*   run `parseTokens <$> readFile "tests/input/t1.hs"` to run t1.hs through the lexer and get the Tokens, (same thing as earlier, start here, check for lexer errors, and if you’re good, move down!)
*   run `parse <$> readFile "tests/input/t1.hs"` to run t1.hs through the lexer and parser and get an Expr,
*   run `execFile "tests/input/t1.hs"` to run t1.hs through your lexer, parser and evaluator, and see what your interpreter is returning.

Replace `t1.hs` with the file you want to test. You could also write your own file and use these methods to test it!
