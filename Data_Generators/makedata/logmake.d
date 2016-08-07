import std.stream;
import std.stdio;
import std.regexp;
import std.conv;
import std.string;
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
	scope Stream fh = new File(file, FileMode.In);
	inputfile = file;

	RegExp titlereg = new RegExp("^@(-?\\d+)\\s+(.+)$", "g");
	RegExp sepreg = new RegExp("##\\s*", "g");

	Log log;
	
	int started = 0;
	int head;
	int num = 0;
	foreach(char line[]; fh) {
		num++;
		line = expandtabs(line.dup);
		if(titlereg.find(line) >= 0) {
			if(started) {
				loglist ~= log;
			} else {
				started = 1;
			}
			head = 1;
			log.id = toShort(titlereg.match(1));
			log.titleline = num;
			log.title = titlereg.match(2).dup;
			log.head = [];//.length = 0;
			log.tail = [];//.length = 0;
		} else if(sepreg.find(line) >= 0) {
			head = 0;
		} else {
			if(started) {
				if(head) {
					log.head ~= line.dup;
				} else {
					log.tail ~= line.dup;
				}
			} else {
				printf("%.*s(%d): text before first title!: %.*s\n", inputfile, num, line);
			}
		}
	}
	if(started) {
		loglist ~= log;
	} else {
		printf("%.*s(%d): No log entries!\n", inputfile, num);
	}
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
			line = line[i + 1..length];
		}
		output ~= line;
	}
	return output;
} 

char [][]trimouterblanks(char [][]input) {
	char [][]output = input;
	while(output.length && strip(output[0]).length == 0) {
		output = output[1..length];
	}
	while(output.length && strip(output[length - 1]).length == 0) {
		output = output[0..length - 1];
	}
	return output;
}

void processlogs() {
	char [][]output;
	foreach(int i, Log log; loglist) {
		printf("%d:%d:[%.*s]\n", log.id, log.title.length, log.title);
		log.head = wraplines(log.head, 49);
		//printf(".\n");
		log.tail = wraplines(log.tail, 49);
		//printf(".\n");
		log.head = trimouterblanks(log.head);
		//printf(".\n");
		log.tail = trimouterblanks(log.tail);
		//printf(".\n");
		if(log.head.length + log.tail.length > 25) {
			printf("%.*s(%d): Text is too long for the log!\n", inputfile, log.titleline);
			output = (log.head ~ log.tail)[0..25];
		} else {
			output.length = 25 - (log.head.length + log.tail.length);
			output[0..length] = "";
			output = log.head ~ output ~ log.tail;
			//printf("X\n");
		}
		int j;
		for(j = 0; j < output.length; j++) {
			printf("%d:[%.*s]\n", output[j].length, output[j]);
			output[j] = output[j] ~ repeat(" ", 49 - output[j].length);
			//printf("%d:[%.*s]\n", output[j].length, output[j]);
			//printf("-\n");
		}
		log.output = output.dup;
		//printf(".\n");
		log.title = log.title ~ repeat(" ", 49 - log.title.length);
		//printf(".\n");
		loglist[i] = log;
		//printf("\n");
	}
}

void writefiles(char []titlefile, char []logfile) {
	scope Stream fhtitles = new File(titlefile, FileMode.OutNew);
	scope Stream fhlogs = new File(logfile, FileMode.OutNew);
	TitleRecord tr;
	LogRecord lr;
	char []s;
	int i;
	foreach(Log log; loglist) {
		tr.id = log.id;
		tr.text(encodestring(log.title));
		for(i = 0; i < 25; i++) {
			//printf("%d:[%.*s]\n", log.output[i].length, log.output[i]);
			s = encodestring(log.output[i]);
			//printf("%d:[%.*s]\n", s.length, s);
			lr.text[i](s);
			//printf("%d:[%.*s]\n", lr.text[i].length, cast(char [])lr.text[i]);
		}
		fhtitles.writeExact(&tr, tr.sizeof);
		fhlogs.writeExact(&lr, lr.sizeof);
	}
}


int main(char [][]arg) {
	parsefile(arg[1]);
	processlogs();
	writefiles(arg[2], arg[3]);
	return 0;
}

