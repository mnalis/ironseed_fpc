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
# along with this program.  If not, see <https://www.gnu.org/licenses/>.
#
# On Debian systems, the complete text of the GNU General Public
# License, version 3, can be found in /usr/share/common-licenses/GPL-3.
#
# Copyright:
#   2020 Matija Nalis <mnalis-git@voyager.hr>

#
# Data Generator: converts standard binary P6 ppm(5) image to data/icons.vga + data/main.pal format used by Ironseed game
#

# FIXME: convert to write to stdout, so we can use it in Makefile

use strict;
use warnings;
use autodie qw/:all/;

my $COLOR_FACTOR = $ENV{COLORF} || 4;	# game seems to be using <<2, which is *4

my $pal_name = $ARGV[0];
my $want_width = $ENV{WIDTH} || 17;
my $want_height = $ENV{HEIGHT} || 15;
my $want_icon_count = $ENV{COUNT} || 81;

if (!defined $pal_name) {
  print "Usage: $0 <main.pal>\n";
  print "Converts PPM file from STDIN (using specified main.pal) to Ironseed 81 icons of 17x15 icons.vga on STDOUT\n";
  exit 1;
}

die "cowardly refusing to write binary file to TTY" if (-t STDOUT);

sub get_line()
{
  my $ret='';
  do { $ret = <STDIN>; } while $ret =~ /^\s*#/;	# skip comments
  chomp $ret;
  return $ret;
}

# FIXME: should support PPM comments, different whitespace etc. see ppm(5)
my $format = get_line();
die "ERROR: P6 PPM file needed, not $format" unless $format eq 'P6';
my ($width, $height) = split ' ', get_line();
die "ERROR: not $want_icon_count icons of ${want_width}x${want_height} but ${width}x${height} PPM file" unless $height==$want_height and $width==$want_width*$want_icon_count ;
my $bpp = get_line();
die "ERROR: must have 255 colors" unless $bpp==255;

undef $/; 	# slurp the rest of the file in one go

# read in palette to %PALETTE
my %PALETTE = ();

open my $pal_fd, '<', $pal_name;
my @_pal = unpack "C*", <$pal_fd>;
close $pal_fd;

for (my $pal_used=0; $pal_used < 768; $pal_used+=3) {
  my $r = $_pal[$pal_used];
  my $g = $_pal[$pal_used+1];
  my $b = $_pal[$pal_used+2];
  my $pal_idx = "$r:$g:$b";
  $PALETTE{$pal_idx} = int($pal_used / 3) if !defined $PALETTE{$pal_idx};
}

# map image colors to palette, store result in @vga_image
my @image = unpack "C*", <STDIN>;
my @vga_image=();

for (my $i = 0; $i < $height * $width * 3; $i+=3) {
  my $r = int($image[$i] / $COLOR_FACTOR);
  my $g = int($image[$i+1] / $COLOR_FACTOR);
  my $b = int($image[$i+2] / $COLOR_FACTOR);
  my $pal_idx = "$r:$g:$b";
  my $val = $PALETTE{$pal_idx};

  if (!defined $val) {		# entry not in palette
     #use Data::Dumper;
     #print Dumper(\%PALETTE);
     die "invalid RGB: $pal_idx not found in $pal_name at idx: $i";
  }

  my $vga_idx = int($i/3);
  $vga_image[$vga_idx] = $val;
}

# sort @vga_image and write to icons.vga file on STDOUT
for my $icon (0 .. $want_icon_count-1) {
  for my $x (0 .. $want_width-1) {
     for my $y (0 .. $want_height-1) {
        my $idx = ($icon * $want_width) + ($y * $want_width * $want_icon_count) + $x;
        my $val = $vga_image[$idx];
        #printf STDERR "icon=$icon x=$x y=$y (idx=$idx, val:     \t%02X)\n", $val;
        print chr($val);
     }
  }
}
