General
=======

For example, to debug savegame #2:

`make debug_sdl && gdb -ex 'break fpc_raiseexception' -ex 'break fpc_assert' -ex 'set non-stop on' -ex 'run' --args ./main /playseed 2`

Extra
=====

Add `-dTrace` to `fpc_debug` in `Makefile` to possibly print more debug info.

Set `DEBUG=1` environment variable to display startup info.

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

  When visiting new system, close enough neighboring systems will become visible.

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
        planet.notes & 125 (01111101) - special- does event() depending on the system index. which means we need at least one scan completed for system event to happen.
        planet.notes & 254 (11111110) = 0  - "System: Scans". It actually shows planets NOT scanned completely!
        &2 AND &32 - Race name (so only if it has LIFE and was CONTACTED)

        - example : planet finished only land, sea, air has: tempplan^[curplan].notes = 28 (00011100), 
        - after all scans completed, it becomes 125 (01111101)
        - after we contact Void dwellers on planet, it becomes 127 (01111111)

- events system (events[], logs[], logpending[] and old ship.events[]) :
	NOTE: ship.events[65] and events[1024] are two different things.

        ship.events[65] is array of bytes, initially fist 50 = 0xff, next 15=0x00
        After adding logs, 255s at the start of array become event numbers (in order of happening?), eg: [10, 11, 255 <repeats 48 times>, 0 <repeats 15 times>]
        it seems that up to some version of the game, ship.events held both events/logs (events with ID<=50).

        Nowadays, if saveX/EVENTS.DTA exists, we load directly:
        - EVENTS.DTA to events[1024] bitmap. event 8 is  "n mod 8" bit in "n/8" byte set to 1. So for example event 11 is 3rd bit in 2nd byte [event[1], as it starts counting from 0])
        - LOGS.DTA to logs[256] array of integers (with -1 meaning no log)
        - PENDING.DTA to logpending[128] of record time,log:integer (created by addpending() so event will happen automatically some time in the future). Currently only used with time=0 (meaning now)

        Otherwise, if those files do not exist (ooold saves?), convertevents() is called which does:
           - copies up to 50 ship.events with ID<50 to logs[], and to converts them into events[] bitmap (having 1024*8 bits for 8192 events)
           - next 15 bytes of ship.events is bitmap; which gets converted to part of events[] too

	events:
		- 500-599: clear before conversations with crew/aliens?
		- 20000-21000 is event initiated by chat with races from  Data_Generators/makedata/event.txt ?

	functions:
		- addlog(n) - adds a log "n" AND an event "n" (via setevent(n))
		- setevent(n) - sets event "n"
		- clearevent(n) - clears event "n"
		- event(n) - handles event "n", and might (or might not) addlog(n) or setevent(n), depending on event number, dependencies etc.

- conversations
	See `Data_Generators/makedata/conv0000.txt` for format of `Data_Generators/makedata/*con1.txt`
	Also `Data_Generators/makedata/template.txt`

	if event is triggered by talks, it is parsed in `comm.pas` in `run20000event()` and `run21000event()`

	Races 0-9 (0=Sengzhac 1=D'pahk 2=Aard 3=Ermigen 4=Titarian 5=Quai_Paloi 6=Scavengers 7=Icon 8=The_Guild 9=Void_Dwellers)
	automatically get event 0-9, by `comm.pas:removedata()` which gets called at the end of `continuecontact()` and does `event(n)` for `n<10`
	Also called is `checkotherevents(n)` which consults `Data_Generators/makedata/event.txt` (with columns `want`, `give` and `message`) which checks:
	- if events (n*10+50) to (n*10+59) has happened, skip the following two points...
	- for `want > 20000`: if there was event `want-20000` - if so, then it calls event `give-20000` (if `give>20000`) or adds cargo `give` if `give<20000` 
	- for `want > 0`: check if there is cargo `want` in hold, and if so removes it. Then it calls event `give-20000` (if `give>20000`) or adds cargo `give` if `give<20000` 
	- for `want = 0` and `give<>0`: it calls event `give-20000` (if `give>20000`) or adds cargo `give` if `give<20000` 
	- in any case, it also calls event (n*10+5x) for each time we triggered the `want`.
