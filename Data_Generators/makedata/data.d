

template PString(int L){
	align(1) struct ps {
		ubyte length;
		char[L] data;
		const int maxlength = L;
		void opCall(char []s) {
			if(s.length > maxlength) {
				this.length = maxlength;
				data[0..this.length] = s[0..this.length];
			} else {
				this.length = s.length;
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
	char keyword[75];
};
struct ResponseRecord {
	short index;
	ubyte responselength;
	char response[255];
};


struct TitleRecord {
	short id;
	PString!(49).ps text;
};

struct LogRecord {
	PString!(49).ps text[25];
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
	char s[];
	int ec;
	foreach(char c; instr) {
		ec = encodechar(c);
		if(ec >= 0) {
			s ~= cast(char)ec;
		}
	}
	return s;
}
