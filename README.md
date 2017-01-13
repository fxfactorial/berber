berber
------

`berber` is a simple command line tool to view `OCaml` documentation
assuming that it was installed with `opam`.

For a hacky terminal handle on the assumed to be HTML documentation, do

```
$ berber cohttp
```

Or to open the docs in a web browsers: 

```
$ berber cohttp --web-browser
```

# Installation

At the moment just do: 

```
$ opam pin add berber git@github.com:fxfactorial/berber.git -y
```

# To other OCaml authors

Please remember that you have a chance to add documentation to your
projects, assuming that you use `ocamldoc` or something that makes
`HTML`. Here's a typical field you can put in opam:

```
build-doc: ["ocaml" "setup.ml" "-doc"]
```
