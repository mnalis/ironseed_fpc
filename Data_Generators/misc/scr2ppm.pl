#!/usr/bin/perl
# Matija Nalis <mnalis-git@voyager.hr>, GPLv3+ started 2020/08
# converts TEMP/*.scr and TEMP/*.pal produced by quicksavescreen() to standard ppm(5) P3 ASCII image

use strict;
use warnings;
use autodie qw/:all/;

my $COLOR_FACTOR=4;	# game seems to be using <<2, which is *4

my $scr = shift;
my $pal = shift;

if (!defined $scr) {
  print "Usage: $0 <file.scr> [file.pal]\n";
  print "Converts Ironseed 320x200 SCR file to PPM on stdout\n";
  print "Display with: $0 TEMP/current.scr | xli -zoom 200 -gamma 1 -dispgamma 1 stdin\n";
  exit 1;
}

undef $/; 	# slurp file in one go

my @PALLETE=();
if (defined $pal) {
  open my $pal_fd, '<', $pal;
  @PALLETE = unpack "C*", <$pal_fd>;
}

print "P3\n320 200\n255\n"; 	# see ppm(5)

open my $scr_fd, '<', $scr;

foreach my $b (unpack "C*", <$scr_fd>) {
  if (@PALLETE) {
     my $c1 = $PALLETE[$b*3] * $COLOR_FACTOR;
     my $c2 = $PALLETE[$b*3+1] * $COLOR_FACTOR;
     my $c3 = $PALLETE[$b*3+2] * $COLOR_FACTOR;
     print "$c1 $c2 $c3\n";
  } else {			# grayscale
     print "$b $b $b\n";
  }
}
