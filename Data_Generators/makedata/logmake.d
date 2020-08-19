import std.stdio;
import std.regex;
import std.conv;
import std.string;
import std.range;
import data;

char []inputfile;

struct Log {
	int titleline;
	int id;
	char []title;
	char [][]head;
	char [][]tail;
	char [][]output;
}

Log []loglist;

void parsefile(char []file) {
	auto fh = File(file, "r");
	inputfile = file;

	auto titlereg = regex("^@(-?\\d+)\\s+(.+)$", "g");
	auto sepreg = regex("##\\s*", "g");

	Log log;
	
	//printf ("Parsing file %s\n", inputfile.toStringz);
	int started = 0;
	int head;
	int num = 0;
	foreach(line; fh.byLine) {
		num++;
		line = detab(line.dup);
		//printf (" parsing line: %s\n", line.toStringz);
		auto title_match = match(line, titlereg);
		if(title_match) {
			if(started) {
				loglist ~= log;
			} else {
				started = 1;
			}
			head = 1;
			log.id = to!short(title_match.captures[1]);
			log.titleline = num;
			log.title = title_match.captures[2].dup;
			log.head = [];//.length = 0;
			log.tail = [];//.length = 0;
			//printf ("  matched title: id=%d, line=%d, title=%s\n", log.id, log.titleline, log.title.toStringz);
		} else if(match(line,sepreg)) {
			head = 0;
			//printf ("  matched separator: %s\n", line.toStringz);
		} else {
			//printf ("  continuation line: %s\n", line.toStringz);
			if(started) {
				if(head) {
					log.head ~= line.dup;
				} else {
					log.tail ~= line.dup;
				}
			} else {
				printf("%s(%d): text before first title!: %s\n", inputfile.toStringz, num, line.toStringz);
			}
		}
	}
	if(started) {
		loglist ~= log;
	} else {
		printf("%s(%d): No log entries!\n", inputfile.toStringz, num);
	}
	//printf ("Done parsing file.\n\n");
}

char [][]wraplines(char [][]text, int width) {
	char [][]output;
	int i, j;
	foreach(char []line; text) {
		while(line.length > width) {
			if(line[width] == ' ') {
				for(i = width; i < line.length && line[i] == ' '; i++) {
					/*do nothing*/
				}
				i--; //adjust i so it points to the last space character.
				for(j = width; j > 0 && line[j] == ' '; j--) {
					/*do nothing*/
				}
			} else {
				for(i = width; i > 0 && line[i] != ' '; i--) {
					/*do nothing*/
				}
				for(j = i; j > 0 && line[j] == ' '; j--) {
					/*do nothing*/
				}
				if(j == 0) {
					j = width;
					i = width - 1;
				}
			}
			output ~= line[0..j + 1];
			line = line[i + 1..$];
		}
		output ~= line;
	}
	return output;
} 

char [][]trimouterblanks(char [][]input) {
	char [][]output = input;
	while(output.length && strip(output[0]).length == 0) {
		output = output[1..$];
	}
	while(output.length && strip(output[$ - 1]).length == 0) {
		output = output[0..$ - 1];
	}
	return output;
}

void processlogs() {
	char [][]output;
	//printf ("Processing logs\n");
	foreach(int i, Log log; loglist) {
		//printf("%d:%d:[%s]\n", log.id, log.title.length, log.title.toStringz);
		log.head = wraplines(log.head, 49);
		//printf(".\n");
		log.tail = wraplines(log.tail, 49);
		//printf(".\n");
		log.head = trimouterblanks(log.head);
		//printf(".\n");
		log.tail = trimouterblanks(log.tail);
		//printf(".\n");
		if(log.head.length + log.tail.length > 25) {
			printf("%s(%d): Text is too long for the log!\n", inputfile.toStringz, log.titleline);
			output = (log.head ~ log.tail)[0..25];
		} else {
			output.length = 25 - (log.head.length + log.tail.length);
			//printf (" head=>%s<\n output[%d]=%s\n tail=>%s<\n", to!string(log.head).toStringz, output.length, to!string(output).toStringz, to!string(log.tail).toStringz);
			output[0..$] = cast(char[])"";
			output = log.head ~ output ~ log.tail;
			//printf("X\n");
		}
		int j;
		for(j = 0; j < output.length; j++) {
			//printf("1> %d:[%s]\n", output[j].length, output[j].toStringz);
			output[j] ~= " ".replicate(49 - output[j].length);
			//printf("2> %d:[%s]\n", output[j].length, output[j].toStringz);
			//printf("-\n");
		}
		log.output = output.dup;
		//printf(".\n");
		log.title = log.title ~ " ".replicate(49 - log.title.length);
		//printf(".\n");
		loglist[i] = log;
		//printf("\n");
	}
	//printf ("Logs processed\n");
}

void writefiles(char []titlefile, char []logfile) {
	//printf ("\nWriting files: titles=%s and logs=%s\n", titlefile.toStringz, logfile.toStringz);
	auto fhtitles = File(titlefile, "wb");
	auto fhlogs = File(logfile, "wb");
	TitleRecord tr;
	LogRecord lr;
	char []s;
	int i;
	foreach(Log log; loglist) {
		tr.id = to!short(log.id);
		tr.text(encodestring(log.title));
		for(i = 0; i < 25; i++) {
			//printf("1> %d:[%s]\n", log.output[i].length, log.output[i].toStringz);
			s = encodestring(log.output[i]);
			//printf("2> %d:[%s]\n", s.length, s.toStringz);
			lr.text[i](s);
			//printf("3> %d:[%s]\n", lr.text[i].length, (cast(char [])lr.text[i]).toStringz);
		}
		fhtitles.rawWrite((&tr)[0..1]);
		//printf ("title_%04d %d:[%s]\n\n", tr.id, tr.text.data.length, tr.text.data.toStringz);
		fhlogs.rawWrite((&lr)[0..1]);
	}
	//printf ("Done writing files.\n");
}


int main(char [][]arg) {
	parsefile(arg[1]);
	processlogs();
	writefiles(arg[2], arg[3]);
	return 0;
}

