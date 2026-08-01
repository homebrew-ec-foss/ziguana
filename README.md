# Ziguana

A toy programming language and transpiler, written in Zig. Ziguana source files (`.zg`) are lexed, parsed, type-checked, and transpiled to C — which is then compiled with `gcc` to produce a native executable.


---

## Try it in 60 seconds

```bash
git clone <your-repo-url>
cd ziguana
zig build

cat > hello.zg << 'EOF'
fn int main() {
    int a = 6;
    int b = 3;
    print("Ziguana Says: Hi");
    return 0;
}
EOF

./zig-out/bin/ziguana hello.zg -o hello
./hello
```

You should see `Ziguana says hi!` printed to your terminal.

---

## Pipeline

```
.zg source
    │
    ▼
  Lexer        tokenizes source, strips whitespace/comments, reports bad tokens with line/column
    │
    ▼
  Parser       builds a validated AST via recursive-descent, full C-style operator precedence
    │
    ▼
  Checker      type-checks the AST (Int / Bool / String / Void), reports semantic errors
    │
    ▼
  Codegen      walks the AST, emits equivalent C source
    │
    ▼
   gcc         compiles the generated C into a native executable
```

## Features

- Single-pass tokenization with descriptive, batched error reporting (no crash-on-first-error)
- Recursive-descent parser with full arithmetic, comparison, bitwise, and logical operator precedence
- Static type checking (`Int`, `Bool`, `String`, `Void`) with function return-path analysis
- String interpolation for expressive `print` statements
- Arrays, functions, `if`/`else`, `while`, and return statements
- Transpiles directly to readable C — inspect the output yourself with `--emit-c`

## CLI usage

Always put the source file path first, then any flags:

```bash
ziguana <file.zg> [flags]
```

| Flag | Description |
|---|---|
| `-o <name>` | Compile straight through to a native executable named `<name>` |
| `--emit-c <file>` | Emit the generated C source to `<file>` instead of compiling it |
| `--astprint` | Print the parsed AST |
| `--tokens` | Print the lexed token stream |
| `--check` | Run the type checker and print any errors (or `No Errors`) |
| `--version` | Print the version |
| `--help` | Show available flags |

Examples:

```bash
ziguana hello.zg -o hello        # compile and produce ./hello
ziguana hello.zg --emit-c out.c  # just emit the C, don't compile
ziguana hello.zg --astprint      # inspect the parsed tree
ziguana hello.zg --check         # type-check only
```

## Language quick reference

**Types:** `int`, `bool`, `string`, `void`

**Operators**, by precedence (loosest to tightest):

```
||  &&                      logical
|  ^  &                     bitwise
==  !=                      equality
<  <=  >  >=                comparison
<<  >>                      shift
+  -                        additive
*  /  %                     multiplicative
-  +  ~                     unary
```

**Example:**

```
fn int clamp(int x, int lo, int hi) {
    if (x < lo) {
        return lo;
    }
    if (x > hi) {
        return hi;
    }
    return x;
}

fn int main() {
    int result = clamp(12, 0, 10);
    print("Clamped: {result}");
    return 0;
}
```

## Project structure

```
src/
├── lexer.zig       tokenizer
├── parser.zig      recursive-descent parser → AST
├── ast.zig          AST node definitions
├── astprinter.zig   debug tree printer (--astprint)
├── checker.zig      static type checker
├── codegen.zig       AST → C source
├── cli.zig           argument parsing
├── fetcher.zig        source file reading
└── main.zig           pipeline entry point
```

## Status

Actively under development as part of a compiler-construction learning project. Expect rough edges — see open issues for current limitations.
