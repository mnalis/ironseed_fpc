import std.array;
import std.stdio;

void main() {
    auto arr = replicate(['s'], 5); // lazy version: https://dlang.org/phobos/std_range.html#repeat
    // or
    auto arr2 = ['s'].replicate(5);
    writeln(arr);
    writeln(arr2);
}
