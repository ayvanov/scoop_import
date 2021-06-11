[![Dart](https://github.com/ayvanov/scoop_import/actions/workflows/dart.yml/badge.svg)](https://github.com/ayvanov/scoop_import/actions/workflows/dart.yml)

[Scoop](https://github.com/lukesampson/scoop)'s missing "import" command implemented in Dart

# Usage

```terminal
scoop install https://github.com/ayvanov/scoop_import/raw/master/scoop-import.json
```
```terminal
scoop-import [path to scoop exported file (scoop export > file) | url (to github gist for example)]
```
When run with no arguments, it will look for a .scoop file in the current directory and then in the home directory of the current user.
