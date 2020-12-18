/********************************************************************
    This file is part of Ironseed.

    Ironseed is free software: you can redistribute it and/or modify
    it under the terms of the GNU General Public License as published by
    the Free Software Foundation, either version 3 of the License, or
    (at your option) any later version.

    Ironseed is distributed in the hope that it will be useful,
    but WITHOUT ANY WARRANTY; without even the implied warranty of
    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
    GNU General Public License for more details.

    You should have received a copy of the GNU General Public License
    along with Ironseed.  If not, see <https://www.gnu.org/licenses/>.
********************************************************************/

/*********************************************
   Data Generator: shared structs for *.d

   Copyright:
    1994 Channel 7, Destiny: Virtual
    2020 Matija Nalis <mnalis-git@voyager.hr>
**********************************************/

import std.conv;

template PString(int L){
	align(1) struct ps {
		ubyte length;
		char[L] data;
		void opCall(char []s) {
			const int maxlength = L;
			assert (maxlength < 255);
			if(s.length > maxlength) {
				this.length = to!ubyte(maxlength);
				data[0..this.length] = s[0..this.length];
			} else {
				this.length = to!ubyte(s.length);
				data[0..s.length] = s[0..s.length];
			}
		}
		char []opCast() {
			return data[0..this.length];
		}
	}
}

struct ConverseRecord {
	short event;
	short runevent;
	short rcode;
	short index;
	ubyte keywordlength;
	char[75] keyword;
};
struct ResponseRecord {
	short index;
	ubyte responselength;
	char[255] response;
};


struct TitleRecord {
	short id;
	PString!(49).ps text;
};

struct LogRecord {
	PString!(49).ps[25] text;
}


int encodechar(char c) {
	if(c >= ' ' && c <= '"') {return c - 31;}
	if(c >= 'A' && c <= 'Z') {return c - 36;}
	if(c >= 'a' && c <= 'z') {return c - 40;}
	if(c >= '\'' && c <= '?') {return c - 35;}
	switch(c) {
	case '%': return 55;
	case '^': return 200;
	case 200: return 200;
	case '@': return 201;
	default: return -1;
	}
}

char []encodestring(char []instr) {
	char[] s;
	int ec;
	foreach(char c; instr) {
		ec = encodechar(c);
		if(ec >= 0) {
			s ~= cast(char)ec;
		}
	}
	return s;
}
