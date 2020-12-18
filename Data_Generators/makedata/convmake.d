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
   Data Generator: Conversation logs generator

   Copyright:
    1994 Channel 7, Destiny: Virtual
    2020 Matija Nalis <mnalis-git@voyager.hr>
**********************************************/

import std.stdio;
import std.ascii;
import std.regex;
import std.conv;
import std.string;
import std.algorithm;
import data;

align(1):

struct Converse {
	int linenum;
	short event;
	short runevent;
	short rcode;
	short index;
	char []keyword;
}

struct Response {
	int linenum;
	short index;
	char []response;
}

Converse []conv;
Response []resp;

char []inputfile;

int [char []]keywordlines;
int [char []]keywordused;
char[][][int] responsekeywords;

int [char []]ignorewords;
int [char []]rootwords;

int lastauto = 1000;
int currentauto = 1000;

void addignore(char []words) {
	foreach(char []s; std.string.split(words)) {
		//printf("ignore:%s\n", s.toStringz);
		ignorewords[to!string(s)] = 0;
	}
}
void addignoremaybe(char []words) {
	foreach(char []s; std.string.split(words)) {
		if(s.length && s[0] == '@') {
			//printf("ignore:%s\n", s.toStringz);
			ignorewords[to!string(s[1..$])] = 0;
		}
	}
}

void addroot(char []words) {
	foreach(char []s; std.string.split(toUpper(words))) {
		//printf("root:%s\n", s.toStringz);
		rootwords[to!string(s)] = 0;
	}
}

void addwordline(int line, char []words) {
	foreach(char []s; std.string.split(toUpper(words))) {
		//printf("line:(%d)%s\n", line, s.toStringz);
		keywordlines[to!string(s)] = line;
	}
}

void parsefile(char []file) {
	auto fh = File(file, "r");
	inputfile = file;
	//auto convreg = regex("^(-?\\d+)\\s+.*");
	auto convreg = regex("^(@)?(-?\\d+)\\s+(-?\\d+)\\s+(-?\\d+)\\s+(-?\\d+)\\s+(\\S.*)", "g");
	auto respreg = regex("^(-?\\d+)\\s+(\\S.*)$", "g");
	auto stopreg = regex("^-500\\s*$", "g");
	auto emptyreg = regex("^\\s*$","g");
	auto ignorereg = regex("^@(.*)$","g");
	auto rootreg = regex("^@\\s*\\^\\s*$", "g");
	Converse c;
	Response r;
	int num = 0;
	foreach(line; fh.byLine) {
		num++;
		line = detab(line);
		//printf("%s\n", line.toStringz);
		auto convreg_match=match(line, convreg);
		if(convreg_match) {
			//printf("conv: %s,%s,%s,%s,%s,%s\n", convreg_match.captures[1].toStringz, convreg_match.captures[2].toStringz, convreg_match.captures[3].toStringz, convreg_match.captures[4].toStringz, convreg_match.captures[5].toStringz, convreg_match.captures[6].toStringz);
			c.linenum = num;
			c.event = to!short(convreg_match.captures[2]);
			c.runevent = to!short(convreg_match.captures[3]);
			c.rcode = to!short(convreg_match.captures[4]);
			c.index = to!short(convreg_match.captures[5]);
			if(c.index < 0) {
				if(lastauto == currentauto) {
					lastauto++;
				}
				c.index = to!short(lastauto);
			}
			c.keyword = cast(char[])(convreg_match.captures[6].dup.toUpper);
			addignoremaybe(c.keyword);
			c.keyword = replace(c.keyword, "@", "");
			addwordline(num, c.keyword);
			if(convreg_match.captures[1] == "@") {
				addroot(c.keyword);
			}
			conv ~= c;
		} else if(auto respreg_match=match(line, respreg)) {
			//printf("resp: %s,%s\n", respreg_match.captures[1].toStringz, respreg_match.captures[2].toStringz);
			r.linenum = num;
			r.index = to!short(respreg_match.captures[1]);
			if(r.index < 0) {
				if(lastauto != currentauto) {
					currentauto++;
				}
				r.index = to!short(currentauto);
			}
			r.response = " " ~ respreg_match.captures[2];
			resp ~= r;
		} else if(auto stopreg_match=match(line, stopreg)) {
			//printf("stop: %s\n", stopreg_match.captures[0].toStringz);
		} else if (match(line, emptyreg)) {
			/*do nothing*/
		} else if (match(line, rootreg)) {
			addroot(c.keyword);
		} else if (auto ignorereg_match=match(line, ignorereg)) {
			addignore(ignorereg_match.captures[1].dup);
		} else {
			printf("%s(%d): bad line: %s\n", inputfile.toStringz, num, line.toStringz);
		}
	}
	
	fh.close();
}

char []matchkeyword(char []instr, char [][]keywords) {
	char []s = toUpper(instr);
	foreach(char []m; keywords) {
		if(m == s) {
			return instr;
		}
	}
	if(s in keywordused) {
		keywordused[to!string(s)] = 1;
		return "^" ~ instr ~ "^";
	}
	return instr;
}

char []dokeyword(char []instr, char [][]keywords) {
	char []outstr = cast(char[])"";
	char []s = cast(char[])"";
	int suppress = 0;
	foreach(int i, char c; instr) {
		if((c >= 'a' && c <= 'z') || (c >= 'A' && c <= 'Z') || (c >= '0' && c <= '9') || c == '-' || c == '\'') {
			s ~= c;
		} else {
			if(s.length) {
				if(suppress) {
					outstr ~= s;
					suppress = 0;
				} else {
					outstr ~= matchkeyword(s, keywords);
				}
				s = cast(char[])"";
			}
			if(c == '_') {
				suppress = 1;
			} else {
				outstr ~= c;
			}
		}
	}
	if(s.length) {
		if(suppress) {
			outstr ~= s;
			suppress = 0;
		} else {
			outstr ~= matchkeyword(s, keywords);
		}
		s = cast(char[])"";
	}
	return outstr;
}

void processconv() {
	char [][]kw;
	foreach(Converse c; conv) {
		kw = std.string.split(c.keyword);
		responsekeywords[c.index] ~= kw;
		foreach(char []w; kw) {
			keywordused[to!string(w)] = 0;
		}
	}
	foreach(int i, Response r; resp) {
		//strip out old keyword highlights
		r.response = join(std.string.split(r.response, "^"), "");
		if(r.index in responsekeywords) {
			r.response = dokeyword(r.response, responsekeywords[r.index]);
		} else {
			printf("There is no matching key word for response index: %d\n", r.index);
		}
		resp[i] = r;
	}
}

void checkall() {
	foreach(kw; keywordused.keys.sort) {
		if(keywordused[kw] == 0 && !(kw in rootwords) && !(kw in ignorewords)) {
			printf("%s(%d):'%s' not used.\n", inputfile.toStringz, keywordlines[kw], kw.toStringz);
		}
	}
}

void dumpall() {
	foreach(Converse c; conv) {
		printf("%d, %d, %d, %d, %s\n", c.event, c.runevent, c.rcode, c.index, c.keyword.toStringz);
	}
	foreach(Response r; resp) {
		printf("%d, %s, %d\n", r.index, r.response.toStringz, r.response.length);
	}
}

void writefiles(char []file) {
	auto fhind = File(file ~ ".ind", "wb");
	auto fhdat = File(file ~ ".dta", "wb");
	ConverseRecord cr;
	ResponseRecord rr;
	char []s;
	cr.keyword[0..$] = 1;
	rr.response[0..$] = 1;
	foreach(Converse c; conv) {
		cr.event = c.event;
		cr.runevent = c.runevent;
		cr.rcode = c.rcode;
		cr.index = c.index;
		s = encodestring(" " ~ c.keyword ~ " ");
		if(s.length > cr.keyword.length) {
			printf("%s(%d): keyword too long, truncated: %s\n", inputfile.toStringz, c.linenum, c.keyword.toStringz);
			s.length = cr.keyword.length;
		}
		cr.keywordlength = to!ubyte(s.length);
		cr.keyword[0..s.length] = s[0..$];
		fhind.rawWrite((&cr)[0..1]);
	}
	foreach(Response r; resp) {
		rr.index = r.index;
		s = encodestring(r.response);
		if(s.length > rr.response.length) {
			printf("%s(%d): response too long, truncated: %s\n", inputfile.toStringz, r.linenum, r.response.toStringz);
			s.length = rr.response.length;
		}
		rr.responselength = to!ubyte(s.length);
		rr.response[0..s.length] = s[0..$];
		fhdat.rawWrite((&rr)[0..1]);
	}
	fhind.close();
	fhdat.close();
}

int main(char [][]arg) {
	parsefile(arg[1]);
	//dumpall();
	processconv();
	//dumpall();
	checkall();
	writefiles(arg[2]);
	return 0;
}
