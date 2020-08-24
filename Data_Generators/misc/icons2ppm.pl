#!/usr/bin/perl
# Matija Nalis <mnalis-git@voyager.hr>, GPLv3+ started 2020/08
# converts data/icons.vga & data/main.pal to standard ppm(5) P3 ASCII image

use strict;
use warnings;
use autodie qw/:all/;

my $COLOR_FACTOR=4;	# game seems to be using <<2, which is *4

my $scr = shift;
my $pal = shift;
my $width = $ENV{WIDTH} || 15;
my $height = $ENV{HEIGHT} || 17;
my $icon_count = $ENV{COUNT} || 81;

if (!defined $scr) {
  print "Usage: $0 <icons.vga> [main.pal]\n";
  print "Converts Ironseed icons.vga 81 17x15 icons file to PPM on stdout\n";
  print "Display with: $0 data/icons.vga data/main.pal | xli -zoom 200 -gamma 1 -dispgamma 1 stdin\n";
  exit 1;
}

undef $/; 	# slurp file in one go

my @PALLETE=();
if (defined $pal) {
  open my $pal_fd, '<', $pal;
  @PALLETE = unpack "C*", <$pal_fd>;
}

print "P3\n";			# see ppm(5)
print $height * $icon_count . "\n";
print $width . "\n";
print "255\n";

open my $scr_fd, '<', $scr;
my @icons = unpack "C*", <$scr_fd>;
close $scr_fd;

for my $x (0 .. $width-1) {
  for my $icon (0 .. $icon_count-1) {
     for my $y (0 .. $height-1) {
        my $idx = ($icon * $width * $height) + ($y * $width) + $x;
        my $b = $icons[$idx];
        if (@PALLETE) {
           my $c1 = $PALLETE[$b*3] * $COLOR_FACTOR;
           my $c2 = $PALLETE[$b*3+1] * $COLOR_FACTOR;
           my $c3 = $PALLETE[$b*3+2] * $COLOR_FACTOR;
           print "$c1 $c2 $c3\n";
        } else {			# grayscale
           print "$b $b $b\n"; # idx=$idx icon=$icon y=$y x=$x\n";
        }
     }
  }
}
