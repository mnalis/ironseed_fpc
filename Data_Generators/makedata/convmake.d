import std.stream;
import std.stdio;
import std.regexp;
import std.conv;
import std.string;
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
char responsekeywords[int][][];

int [char []]ignorewords;
int [char []]rootwords;

int lastauto = 1000;
int currentauto = 1000;

void addignore(char []words) {
	foreach(char []s; std.string.split(words)) {
		//printf("ignore:%.*s\n", s);
		ignorewords[s] = 0;
	}
}
void addignoremaybe(char []words) {
	foreach(char []s; std.string.split(words)) {
		if(s.length && s[0] == '@') {
			//printf("ignore:%.*s\n", s);
			ignorewords[s[1..length]] = 0;
		}
	}
}

void addroot(char []words) {
	foreach(char []s; std.string.split(toupper(words))) {
		//printf("root:%.*s\n", s);
		rootwords[s] = 0;
	}
}

void addwordline(int line, char []words) {
	foreach(char []s; std.string.split(toupper(words))) {
		//printf("line:(%d)%.*s\n", s);
		keywordlines[s] = line;
	}
}

void parsefile(char []file) {
	scope Stream fh = new File(file, FileMode.In);
	inputfile = file;
	//RegExp convreg = new RegExp("^(-?\\d+)\\s+.*");
	RegExp convreg = new RegExp("^(@)?(-?\\d+)\\s+(-?\\d+)\\s+(-?\\d+)\\s+(-?\\d+)\\s+(\\S.*)", "g");
	RegExp respreg = new RegExp("^(-?\\d+)\\s+(\\S.*)$", "g");
	RegExp stopreg = new RegExp("^-500\\s*$", "g");
	RegExp emptyreg = new RegExp("^\\s*$","g");
	RegExp ignorereg = new RegExp("^@(.*)$","g");
	RegExp rootreg = new RegExp("^@\\s*\\^\\s*$", "g");
	Converse c;
	Response r;
	int num = 0;
	foreach(char line[]; fh) {
		num++;
		line = expandtabs(line);
		//printf("%.*s\n", line);
		if(convreg.find(line) >= 0) {
			//printf("conv: %.*s,%.*s,%.*s,%.*s,%.*s,%.*s\n", convreg.match(1), convreg.match(2), convreg.match(3), convreg.match(4), convreg.match(5), convreg.match(5));
			c.linenum = num;
			c.event = toShort(convreg.match(2));
			c.runevent = toShort(convreg.match(3));
			c.rcode = toShort(convreg.match(4));
			c.index = toShort(convreg.match(5));
			if(c.index < 0) {
				if(lastauto == currentauto) {
					lastauto++;
				}
				c.index = lastauto;
			}
			c.keyword = toupper(convreg.match(6).dup);
			addignoremaybe(c.keyword);
			c.keyword = replace(c.keyword, "@", "");
			addwordline(num, c.keyword);
			if(convreg.match(1) == "@") {
				addroot(c.keyword);
			}
			conv ~= c;
		} else if(respreg.find(line) >= 0) {
			//printf("resp: %.*s,%.*s\n", respreg.match(1), respreg.match(2));
			r.linenum = num;
			r.index = toShort(respreg.match(1));
			if(r.index < 0) {
				if(lastauto != currentauto) {
					currentauto++;
				}
				r.index = currentauto;
			}
			r.response = " " ~ respreg.match(2);
			resp ~= r;
		} else if(stopreg.find(line) >= 0) {
			//printf("stop: %.*s\n", stopreg.match(0));
		} else if (emptyreg.find(line) >= 0) {
			/*do nothing*/
		} else if (rootreg.find(line) >= 0) {
			addroot(c.keyword);
		} else if (ignorereg.find(line) >= 0) {
			addignore(ignorereg.match(1).dup);
		} else {
			printf("%.*s(%d): bad line: %.*s\n", inputfile, num, line);
		}
	}
	
	fh.close();
}

char []matchkeyword(char []instr, char [][]keywords) {
	char []s = toupper(instr);
	foreach(char []m; keywords) {
		if(m == s) {
			return instr;
		}
	}
	if(s in keywordused) {
		keywordused[s] = 1;
		return "^" ~ instr ~ "^";
	}
	return instr;
}

char []dokeyword(char []instr, char [][]keywords) {
	char []outstr = "";
	char []s = "";
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
				s = "";
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
		s = "";
	}
	return outstr;
}

void processconv() {
	char [][]kw;
	foreach(Converse c; conv) {
		kw = std.string.split(c.keyword);
		responsekeywords[c.index] ~= kw;
		foreach(char []w; kw) {
			keywordused[w] = 0;
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
	foreach(char []kw; keywordused.keys.sort) {
		if(keywordused[kw] == 0 && !(kw in rootwords) && !(kw in ignorewords)) {
			printf("%.*s(%d):'%.*s' not used.\n", inputfile, keywordlines[kw], kw);
		}
	}
}

void dumpall() {
	foreach(Converse c; conv) {
		printf("%d, %d, %d, %d, %.*s\n", c.event, c.runevent, c.rcode, c.index, c.keyword);
	}
	foreach(Response r; resp) {
		printf("%d, %.*s, %d\n", r.index, r.response, r.response.length);
	}
}

void writefiles(char []file) {
	scope Stream fhind = new File(file ~ ".ind", FileMode.OutNew);
	scope Stream fhdat = new File(file ~ ".dta", FileMode.OutNew);
	ConverseRecord cr;
	ResponseRecord rr;
	char []s;
	cr.keyword[0..length] = 1;
	rr.response[0..length] = 1;
	foreach(Converse c; conv) {
		cr.event = c.event;
		cr.runevent = c.runevent;
		cr.rcode = c.rcode;
		cr.index = c.index;
		s = encodestring(" " ~ c.keyword ~ " ");
		if(s.length > cr.keyword.length) {
			printf("%.*s(%d): keyword too long, truncated: %.*s\n", inputfile, c.linenum, c.keyword);
			s.length = cr.keyword.length;
		}
		cr.keywordlength = s.length;
		cr.keyword[0..s.length] = s[0..length];
		fhind.writeExact(&cr, cr.sizeof);
	}
	foreach(Response r; resp) {
		rr.index = r.index;
		s = encodestring(r.response);
		if(s.length > rr.response.length) {
			printf("%.*s(%d): response too long, truncated: %.*s\n", inputfile, r.linenum, r.response);
			s.length = rr.response.length;
		}
		rr.responselength = s.length;
		rr.response[0..s.length] = s[0..length];
		fhdat.writeExact(&rr, rr.sizeof);
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
