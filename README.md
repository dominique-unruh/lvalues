Isabelle theories accompanying the paper "Registers in quantum and classical imperative languages".

To open these theories in [Isabelle 2021](https://isabelle.in.tum.de/), start Isabelle with the following command line:
```
/opt/Isabelle2021/bin/isabelle jedit -d . -l LValues-Prerequisites  [theory files]
```
while in the directory with the theory files. (Replace `/opt/Isabelle2021` by wherever Isabelle is installed.)

You need to have the AFP installed and configured (see https://www.isa-afp.org/using.html).

There is no need to install the bounded operators library, the correct version is included with these theories.
(It should be in the subdirectory `bounded_operators`. When checking out the git repository, you need to run `git submodule update --init bounded-operators
` to initialize that subdirectory.)
