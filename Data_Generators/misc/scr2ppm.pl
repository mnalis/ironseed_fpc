#!/usr/bin/perl
#
# This program is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program.  If not, see <http://www.gnu.org/licenses/>.
#
# On Debian systems, the complete text of the GNU General Public
# License, version 3, can be found in /usr/share/common-licenses/GPL-3.
#
# Copyright:
#   2020 Matija Nalis <mnalis-git@voyager.hr>

#
# Data Generator: converts TEMP/*.scr and TEMP/*.pal produced by quicksavescreen() to standard ppm(5) P3 ASCII image
#

use strict;
use warnings;
use autodie qw/:all/;

my $COLOR_FACTOR = $ENV{COLORF} || 4;	# game seems to be using <<2, which is *4

my $scr = shift;
my $pal = shift;
my $want_width = $ENV{WIDTH} || 320;
my $want_height = $ENV{HEIGHT} || 200;

if (!defined $scr) {
  print "Usage: $0 <file.scr> [file.pal]\n";
  print "Converts Ironseed 320x200 (or other specified size via ENV) SCR file to PPM on stdout\n";
  print "Display with: $0 TEMP/current.scr data/main.pal | xli -zoom 200 -gamma 1 -dispgamma 1 stdin\n";
  exit 1;
}

undef $/; 	# slurp file in one go

my @PALETTE=();
if (defined $pal) {
  open my $pal_fd, '<', $pal;
  @PALETTE = unpack "C*", <$pal_fd>;
}

print "P3\n$want_width $want_height\n255\n"; 	# see ppm(5)

open my $scr_fd, '<', $scr;
my $pixels = 1;
foreach my $b (unpack "C*", <$scr_fd>) {
  if (@PALETTE) {
     my $c1 = $PALETTE[$b*3] * $COLOR_FACTOR;
     my $c2 = $PALETTE[$b*3+1] * $COLOR_FACTOR;
     my $c3 = $PALETTE[$b*3+2] * $COLOR_FACTOR;
     print "$c1 $c2 $c3\n";
  } else {			# grayscale
     print "$b $b $b\n";
  }
  #last if $pixels++ > $want_width * $want_height;
}
