import std.stdio;
import std.conv;

template PString(int L){
        align(1) struct ps {
                ubyte length;
                char[L] data;
                const int maxlength = L;
                void opCall(char []s) {
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

struct TitleRecord {
        short id;
        char[49] text;
        //PString!(49).ps text;
};

TitleRecord tr;

void main()
{


auto stream = File("filename","wb+");
 tr.id = 1234;
 tr.text = "hello world";
 //tr.text ( cast(char[])  "hello world!" );
 //ubyte[] outstring = cast(ubyte[]) "blabla";

 writeln(tr);
 //stream.write(tr);
 //stream.rawWrite(tr);
 stream.rawWrite((&tr)[0..1]);  // see https://stackoverflow.com/a/63489442/2600099
 //stream.rawWrite([tr]);
 //stream.rawWrite(cast(ubyte[52]) tr);
 //stream.rawWrite(cast(ubyte[]) tr);
 //fwrite(&tr, 4, 1, stream);

 //stream.rewind();
 //auto inbytes = new char[4];
 //stream.rawRead(inbytes);
 //writeln("inbytes=",inbytes);
 //assert(inbytes[3] == outstring[3]);
}

