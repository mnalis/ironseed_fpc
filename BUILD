Software required to build:

	Borland Pascal 7 is requird to build the game and some tools used to create data files.

	The Digital Mars D compiler is required to the conversation and log conversion tools.
		http://digitalmars.com/d/1.0/index.html

	Borland's BGI Toolkit is required for VGA256.BGI

	Python is required for the fixnames.py script. This converts all files in a directory in lowercase.

Wine/DOSBox setup:
	The Makefile assumes that Borland Pascal has been installed to F:\BP and Ironseed is placed in S:\IRONSEED

	The command "sudo echo 0 > /proc/sys/vm/mmap_min_addr" may be required to run DOS executables under Wine. Newer versions of Wine may invoke DOSBox execute the command.


Borland Pascal 7 setup:
	The directories use in Borland Pascal need to be configured.
	Run BP and in the menu "Options -> Directories" configure the directories like below.
		EXE & TPU directory:  s:\ironseed\code
		Include directories:  s:\ironseed\code;s:\ironseed\dmp
		Unit directories:     s:\ironseed\code;s:\ironseed\dmp;f:\bp\units;f:\bp\winunits
		Object directories:   s:\ironseed\code;s:\ironseed\dmp
		Resource directories: f:\bp\units;

BGI Toolkit:
	VGA256.BGI should be extracted from the toolkit. It should be then converted to a .OBJ file with BINOBJ.EXE included with Borland Pascal.
	VGA256.OBJ should be place in ironseed/code