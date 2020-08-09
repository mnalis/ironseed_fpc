ironseed_fpc
============
Iron Seed is a science-fiction DOS game from 1994, which was both developed and published by Channel 7.
Gameplay is real-time, featuring trading, diplomacy, and strategy.
This repository contains a free pascal version of the original source code, so the game can now be compiled and run on GNU/Linux.
Mnalis is providing ongoing bug fixes which are being integrated into this repository, further bug fixing and contributors are welcome.

Documentation
=============
- `Documents/ironseed-manual.txt` is old ironseed manual, not completely up-to-date
- `Documents/changelog.txt` contains current SDL/fpc development log.
- `Documents/version.txt` is original developers historic (DOS) version list.
- `Documents/todo.txt` is original developers historic (DOS) TODO file.
- Current TODO is online at https://github.com/mnalis/ironseed_fpc/issues

Compilation
===========
Just typing `make` will compile whichever developers think is currently the best.
You can also force the version to build, by `make debug_sdl` for SDL-only version,
or `make debug_ogl` for SDL+OpenGL-enabled version.

There are also no-seatbelts targets `release_sdl` and `release_ogl` but they
are not recommended at the moment as they do not have anti-data-corruption
checks, so bugs could creep up in your savefiles! Or, just for fun, you can also
build `demo_sdl`, which is original shareware demo restricted version.

Running
=======
./is
