General
=======

For example, to debug savegame #2:

`make debug_sdl && gdb -ex 'break fpc_raiseexception' -ex 'break fpc_assert' -ex 'set non-stop on' -ex 'run' --args ./main /playseed 2`


GDB bugs displaying RECORD
==========================
  https://wiki.lazarus.freepascal.org/GDB_Debugger_Tips
  You need (still in gdb 8.2.1) to manually cast pointers to RECORD types:

        (gdb) p tempplan^[curplan].cache
        Type PLANARRAY is not a structure or union type.

        (gdb) ptype tempplan^[curplan]
        type = PLANETTYPE = class
          public
            SYSTEM : BYTE;
            [...]
            CACHE : array [1..7] of WORD;
            AGE : LONGINT;
        end

        (gdb) p PLANETTYPE(tempplan^[curplan]).cache
        $42 = {5000, 5100, 5140, 0, 5040, 0, 5020}


Data structures
===============
- system[index].notes

        system.notes & 1 - known (visible on map)

  When visiting new system, close enough neighbouring systems will become visible.

- tempplan^[curplan].notes

        planet.notes & 1   b0 - ALL scans (1-5) complete
        planet.notes & 2   b1 - planet with contacts
        planet.notes & 4   b2 - scan1 finished (land)
        planet.notes & 8   b3 - scan2 finished (sea)
        planet.notes & 16  b4 - scan3 finished (air)
        planet.notes & 32  b5 - scan4 finished (life)
        planet.notes & 64  b6 - scan5 finished (anomalies)
        planet.notes & 128 b7 - (unused?)

                           b76543210
        planet.notes & 125 (01111101) - special- does event() depening on the system index. which means we need at least one scan completed for system event to happen.
        planet.notes & 254 (11111110) = 0  - "System: Scans". It actually shows planets NOT scanned completely!
        &2 AND &32 - Race name (so only if it has LIFE and was CONTACTED)

        - example : planet finished only land, sea, air has: tempplan^[curplan].notes = 28 (00011100), 
        - after all scans completed, it becomes 125 (01111101)
        - after we contact Void dwellers on planet, it becomes 127 (01111111)
