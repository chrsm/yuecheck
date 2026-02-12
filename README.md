yuecheck
===

Tools for writing [Yuescript][1].

- linter (`yuecheck`)
- formatter (`yuefmt`)

`yuecheck` came about due to the fact that I love writing code in Yuescript, but
there aren't really any tools for it. It started as a standard linter I am attempting
to expand that to a formatter (`yuefmt`).

`yuefmt`, much like `yuecheck`, is based on my opinions of how code should be
written and formatted. `yuecheck` is configurable at this point but `yuefmt` lacks
that. There may be things I will make configurable but ultimately it was a huge
PITA to put together. If you have any suggestions, please feel free to file an
issue.


----

Current TODOs:

- [ ] General cleanup. Rules are ugly for implementation
  * [x] categorized, but still more to do
- [ ] More fleshed out LSP implementation. Unlikely this will be very advanced,
  and less likely will it work with non-Yue code. Possibly could redirect to
  luals.

* [installation](#installation)
* [yuecheck usage](#usage-of-yuecheck)
* [yuefmt usage](#usage-of-yuefmt)
* [configuration](#configuration)
  * [enabling and disabling checks](#enabling-and-disabling-checks)
* [built-in lint rules](#built-in-linters)
* [writing custom rules](#writing-custom-rules)
* [contributing](#contributing)
* [example neovim setup](#example-neovim-setup)
* [changelog](#changelog)


# installation

There is a rockspec, but yuecheck is not yet available on luarocks. It is the
recommended way to install, however, to provide the `yuecheck` command.

```bash
git clone git@github.com:chrsm/yuecheck.git
cd yuecheck
luarocks make
# or luarocks --local make
```

# usage of yuecheck

To lint a specific file or directory, pass it as an argument to `yuecheck`,
ex `yuecheck .` (all yue files in cwd) or `yuecheck specific.yue` for a single file.

See below for other options.

```
Usage: yuecheck [-h] [--ignore-config] [-j]
       ([-d <directory>] | [-f <file>] | [<dir_or_file>] | [--stdin])
       [-x [<exclude>] ...]

Options:
   -h, --help            Show this help message and exit.
            -d <directory>,
   --directory <directory>
                         directory containing files to check
       -f <file>,        specific file to check
   --file <file>
   --stdin               parse stdin
   --ignore-config       ignore repo or user config
   -j, --json            output as json
          -x [<exclude>] ...,
   --exclude [<exclude>] ...
                         pattern for paths to exclude

```

Simple example: `sample.yue`

```moonscript
x = "abcd"
```

```
$ yuecheck sample.yue
sample.yue:1:3: double-quoted string where single-quoted would suffice

1 issues
```


# usage of yuefmt

To format a specific file, pass it as an argument to `yuefmt`, eg `yuefmt file.yue`.
You can also pass via `-f file.yue` or pump to `yuefmt` via stdin (`--stdin`).

See below for other options.

```
Usage: yuefmt [-h] [-w] ([-f <file>] | [<dir_or_file>] | [--stdin])
       [-x [<exclude>] ...]

tool for formatting yue code

Arguments:
   dir_or_file

Options:
   -h, --help            Show this help message and exit.
       -f <file>,        file to format
   --file <file>
   --stdin               parse stdin
          -x [<exclude>] ...,
   --exclude [<exclude>] ...
                         pattern for paths to exclude
   -w, --write           write changes to disk

see https://github.com/chrsm/yuecheck
```



## example neovim setup

If you're a neovim user, you can refer to my dotfiles for how I hooked this up via [nvim-lint][2]:
[nvim_lint config][3].


# configuration

All rules are enabled by default. For further customization, it is recommended
to write a `.yuecheck` file with your desired settings. This file can be placed
in two locations:

- `(root dir with .git)/.yuecheck`
  * TODO: make this so that yuecheck must trust it first, since it can run code.
- `$HOME/.yuecheck`

Repo-specific configuration files take precedence over the user-level file.

This file is a yue script itself, so you can write it however you prefer, so long
as it returns a table matching the spec below. Note that this file is not
required. Check the repo's `.yuecheck` file for a full example.

```moonscript
export default {
  -- !!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
  -- NOTE! Set this to true only if you trust the code you're linting.
  -- yuecheck currently doesn't certain things (const checks), and uses
  -- the yue compiler to try to check for additional errors.
  --
  -- the code itself is not executed, but macros are run by the compiler,
  -- and therefore side effects can occur.
  --
  -- !!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
  enable_compilation: false

  -- if a rule is missing or set to false, it is disabled.
  enabled_rules:
    -- by default, all rules are set to enabled at runtime.
    cond_identical_exprs: true
    cond_impossible: true
    unreachable: true
    basic_nilness: true

    global_writes: true
    stdlib_usage: true
    stdlib_match: true

    style_comment_space: true
    style_zero_index: true
    style_import_as_ident: true
    style_unnecessary_doublestring: true
    style_conditionals: true
    style_simplify_if_to_switch: true
    style_discourage_require: true
    style_discourage_unnecessary_sb: true

  -- per-rule configuration, where possible
  rules:
    global_writes:
      patterns: [ '^_ENV', '^package' ]
}
```

Another example - adding more checks to `stdlib_usage`.

```moonscript
import 'yuecheck.rules'

custom_rules =
  stdlib_usage:
    definitions:
      love:
        filesystem:
          append:
            args:
              * name: 'name', optional: false
              * name: 'data', optional: false
              * name: 'size', optional: true

-- if you want to keep the current definitions, merge
for k, v in pairs rules.stdlib_usage.config.definitions
  custom_rules.stdlib_usage.definitions[k] = v

cfg =
  rules: custom_rules

  enabled_rules:
    stdlib_usage: true

export default cfg
```


## enabling and disabling checks

### per project

Configuration can be set up at the root of the repository. The config is Yuescript,
so you can write it however you want. Some rules allow additional configuration.

Example below.

```moonscript
export default {
  enabled_rules:
    stdlib_usage: true
    global_writes: false
    cond_identical_exprs: true
    cond_impossible: true
    style_comment_space: true

  rules:
    global_writes:
      patterns: { '^_ENV', '^package' }
}
```


### per file

Linters can be disabled by having a comment at the top of the file, even if
the config file or command line arguments enable them.

```moonscript
-- yuecheck:ignore=stdlib_usage,smell_global_writes

_G['a'] = 'ignored'
os.clock 'ignored'
```

```moonscript
-- yuecheck:ignore

_G['is also'] = 'acceptable'
```


### per line

```moonscript
_G['a'] = 'ignored' -- yuecheck:ignore
os.clock 'not ignored'
```


# built-in lint rules

More to come, most likely. Most of these are style/preference, or ahead-of-time checks
before running.

| Rule | Description |
| :---- | ----------- |
| style_comment_space | Comments must have a space between `--` or `--[[` and content |
| style_zero_index | Discourages use of t[0], as tables usually start at 1; Using 0 is likely unintentional. |
| style_import_as_ident | Warns on redundant import name, i.e. `import 'x' as x` |
| style_unnecessary_doublestring | Warns on unnecessary use of `"` for strings where `'` is fine |
| style_discourage_require | Discourages use of `require` in favor of `import` |
| style_discourage_unnecessary_sb | Discourages use of square brackets in table literals, eg `{ ['a']: true }` can be `{ a: true }` |
| ... | ... |
| style_conditionals | Warns on odd conditionals, eg `if true`, `unless false` always execute |
| style_simplify_if_switch | Warns on chain if-elseif that could be switch instead | 
| ... | ... |
| stdlib_usage | Finds issues with standard library functions. Configurable. |
| stdlib_match | Finds issues with patterns supplied to string.(match,find,gmatch,gsub) and capture groups |
| ... | ... |
| global_writes | Warns on writes to global variables (`_G`, `_ENV`, etc). Configurable. |
| ... | ... |
| cond_identical_exprs | Warns on conditions that compare a value to itself |
| cond_impossible | Warns on some types of impossible conditions |
| unreachable | Warns on code that is unreachable |
| basic_nilness | Warns on certain types of nil checks that aren't necessary |
| nil_comparisons | Warns about syntax errors from conditions against nil |


# writing custom rules

Custom checks can be added to the linter very easily. The best way to add one
is by adding it to your `.yuecheck` file.

```moonscript
import 'yuecheck.types'
import 'yuecheck.linter'

config =
  enabled_rules:
    my_check: true

my_check =
  type: 'wat'
  name: 'my_check'
  on:
    * types.Value
  check: (node) ->
    unless some_condition node
      return

    {
      type: 'WARN'
      message: "value found"
      line: node\g_src_line!
      col: node\g_src_col!
    }

linter.define_rule my_check

export default config
```

Return values from a check should be:
```moonscript
{
  type: string HINT|INFO|WARN|ERROR
  message: string
  line: int
  col: int
}
-- or a table of tables
{
  result1, result2, ...
}
```

While `type` string value is not enforced, it is useful to be consistent for
integrations with other tools.

NOTE:

Currently there is some work in making rules easier to declare, such that
if you are looking for specific things, there will be an easier way to
retrieve information than looking at the full node tree everywhere.

You can look at `src/yuecheck/rules.yue` `stdlib_match`, which uses the premade
`FuncRule`.


# important notes

## AST simplification

`yue.to_ast` even with flatten=0 does simplify some parts, requiring specific
handling within `linter.build_ast`.

- `TableLit` with empty `.values` is returned with `{ }`
- `FnArgDefList` will have an empty '' when `f = () ->` is used instead of `f = ->`
- `Return` will have a 'return' when `f = -> return` (vs `f = ->`)
- `DefaultValue` will have '' sometimes (I didn't document why, sorry!)
- `DoubleString` sometimes has '' instead of `DoubleString>DoubleStringContent>DoubleStringInner ''`
- `x^2` `^` is lost, resulting in only `Callable + Value`, unlike other operators
- `r[#r]` is returned as literal `[#r]` instead of `ReversedIndex`.

There are likely more simplifications that are not listed. I am adding cases as I find them.


## type definitions

`src/types.yue` is a generated file. To regenerate it, run `make generate`.

This calls two scripts:
- `bin/fetch_ast.yue`
  * fetches `yue_ast.h` header from [Yuescript][1] repo
  * does some simple parsing of types
  * has a few manual overrides because I'm lazy and haven't made it parse better
  * generates `gen/types_raw.yue` (ignored in .gitignore)
- `bin/generate_types.yue`
  * imports `gen/types_raw.yue` and generates `src/types.yue`
  * has all types specified as actual `class` instances
  * allows walking ast and comparing types


## comments

Comments from `yue.to_ast` are only preserved on `Statement`.

```moonscript
-- a
-- b
c = 1
-- .comments[] { '-- a', '-- b' }
```

Comments that are not a immediately preceding a statement are lost as expected.
```moonscript
-- a
-- b

print 1 -- .comments[] {}

print 1 -- comment
--^ .comments[] {} <- not present, too
```

Multiline comments swallow all surrounding whitespace.
And despite `Statement<.comments<YueLineComment,YueMultilineComment>>`, `to_ast`
simplifies to `YueLineComment|MultilineCommentInner`.

```moonscript
-- a
-- b
--[[ c ]]
d = 1
-- .comments[] { LineComment'-- a', LineComment'-- b', MultilineComment'c' }

-- same result regardless of whitespace
-- [[
  c
]]
```

While this library does handle constructing these when they are added to
statements, it also has a crude comment 'parser' itself that maps lines
to comments.

```moonscript
src = "-- comment1\nb = 1 -- comment 2\n\n-- comment 3\n...etc"

-- returns t{ indices: { line# that has comment, ... }, [line#]: { YueLineComment|YueMultilineComment, ... }
-- indices are useful if you want to just know which lines have comments or iter, as table holes will prevent
-- full iteration.
comments = linter.find_comments src 

for idx in *comments.indices
  for v in *comments[idx]
    -- depending on YueMultilineComment or YueLineComment val
    print v.inner?.v ?? v.v
```


# contributing

- **don't be an ass**
- write decent commit messages


[1]: https://github.com/IppClub/YueScript
[2]: https://github.com/mfussenegger/nvim-lint
[3]: https://github.com/chrsm/dotfiles/blob/master/neovim/.config/nvim/lua/plug/nvim_lint.yue#L14


# changelog

2026-02
  * implemented `yuefmt`, a tool for formatting yue code
  * WONTFIX'd .yuecheck comp protection; so little use of yue that this seems unnecessary and annoying

2026-01
  * updated to YueScript 0.32.4; possible breaking changes


