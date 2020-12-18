ironseed_fpc
============
Iron Seed is a science-fiction DOS game from 1994, which was both developed and published by Channel 7.
Gameplay is real-time, featuring trading, diplomacy, and strategy.
This repository contains a free pascal version of the original source code which has been released under GPL-3.0-or-later (see LICENSE file),
so the game can now be compiled and run on GNU/Linux on architectures supported by fpc (tested on x86_64 and i386).
Mnalis is providing ongoing bug fixes which are being integrated into this repository, further bug fixing and contributors are welcome.

Documentation
=============
- `Documents/is.6` is a man page
- `Documents/ironseed-manual.txt` is old ironseed manual, not completely up-to-date
- `Documents/changelog.txt` contains current SDL/fpc development log.
- `Documents/old_version.txt` is original developers historic (DOS) version list.
- `Documents/old_todo.txt` is original developers historic (DOS) TODO file.
- Current TODO is online at https://github.com/mnalis/ironseed_fpc/issues

Prerequisites
=============
For compiling, you need:
- fpc (Free pascal compiler, `apt-get install fpc`)
- gcc (GNU C Compiler, `apt-get install build-essential gcc`
- SDL v1.2 (Simple DirectMedia Layer 1.2, `apt-get install libsdl1.2-dev libsdl-mixer1.2-dev`)
- (optionally) OpenGL (`apt-get install mesa-common-dev`)

For making changes to game, you may also need:
- (optionally) D compiler (The D compiler is required to the conversation and log conversion tools, `apt-get install ldc` / `apt-get install gdc` or http://digitalmars.com/d/2.0/)
- (optionally) perl, imagemagick, graphicsmagick (for screen conversion utilities, `apt-get install perl graphicsmagick imagemagick`)

Debian packages and prebuilt game
=================================
- source for Debian packages can be found on https://mentors.debian.net/package/ironseed/
  Just do `dget -x https://mentors.debian.net/debian/pool/main/i/ironseed/ironseed_XXXX.dsc`
  on the latest `.dsc` file, and `debuild` (from `devscripts` package) to rebuild.
  Packaging information is being maintained on  https://salsa.debian.org/mnalis/ironseed

- prebuilt .deb packages for Debian Buster can also often be found at
  https://github.com/mnalis/ironseed_fpc/releases

Compilation
===========
Just typing `make` will compile whichever developers think is currently the best.
You can also force the version to build, by `make debug_sdl` for SDL-only version,
or `make debug_ogl` for SDL+OpenGL-enabled version.

There are also no-seatbelts targets `release_sdl` and `release_ogl` but they
are not recommended at the moment as they do not have anti-data-corruption
checks, so bugs could creep up in your savefiles! Or, just for fun, you can also
build `demo_sdl`, which is original shareware demo restricted version.

Running from build directory for test
=====================================
`./is`

Installing
==========
`make all install`

Creating Debian package
=======================
`sudo apt-get install devscripts; debuild`

Old savegames
=============
Previously, savegames resided in `data/savegame.dir` and `save?` subdirectories
in build directory. They now reside in `~/.local/share/ironseed` (or `~/.ironseed`).

Debug
=====
see `Documents/debug_notes.md`
