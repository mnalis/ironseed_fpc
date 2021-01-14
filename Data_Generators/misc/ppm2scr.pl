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
# Data Generator: converts standard binary P6 ppm(5) image to  TEMP/*.scr + TEMP/*.pal format used by quickloadscreen() 
#

use strict;
use warnings;
use autodie qw/:all/;

my $COLOR_FACTOR = $ENV{COLORF} || 4;	# game seems to be using <<2, which is *4

my $basename = $ARGV[0];
my $ppm_name = $basename;
my $want_width = $ENV{WIDTH} || 320;
my $want_height = $ENV{HEIGHT} || 200;

if (!defined $ppm_name) {
  print "Usage: $0 <BASENAME.ppm>\n";
  print "Converts PPM file to Ironseed 320x200 (or other specified size via ENV) BASENAME.scr and BASENAME.pal files\n";
  exit 1;
}

die "$basename does not look like .ppm file" unless $basename =~ s{\.ppm$}{}i;

my $pal_final = $basename . '.pal';
my $scr_final = $basename . '.scr';
my $pal_tmp = $pal_final . '.tmp';
my $scr_tmp = $scr_final . '.tmp';


open my $ppm_fd, '<', $ppm_name;

sub get_line()
{
  my $ret='';
  do { $ret = <$ppm_fd>; } while $ret =~ /^\s*#/;	# skip comments
  chomp $ret;
  return $ret;
}

# FIXME: should support PPM comments, different whitespace etc. see ppm(5)
my $format = get_line();
die "ERROR: P6 PPM file needed, not $format" unless $format eq 'P6';
my ($width, $height) = split ' ', get_line();
die "ERROR: not ${want_width}x${want_height} PPM file" unless $width==$want_width and $height==$want_height;
my $bpp = get_line();
die "ERROR: must have 255 colors" unless $bpp==255;

undef $/; 	# slurp the rest of the file in one go
my @SCR = unpack "C*", <$ppm_fd>;
my %PALETTE = ();
my $pal_used = 0;

open my $pal_fd, '>', $pal_tmp;
open my $scr_fd, '>', $scr_tmp;

my $remains=64000;
for (my $i = 0; $i < $width * $height * 3; $i+=3) {
  my $r = int($SCR[$i] / $COLOR_FACTOR);
  my $g = int($SCR[$i+1] / $COLOR_FACTOR);
  my $b = int($SCR[$i+2] / $COLOR_FACTOR);
  my $pal_idx = "$r:$g:$b";
  my $val = $PALETTE{$pal_idx};
  
  if (!defined $val) {		# add new entry to palette
     $val = $pal_used++;
     die "ERROR: palette overflow: $pal_used" if $val > $bpp;
     $PALETTE{$pal_idx} = $val;
     print $pal_fd chr($r).chr($g).chr($b);
  }
  
  print $scr_fd chr($val);
  $remains--;
}

print $scr_fd chr(0) x $remains;	# fillup so scr2cpr.pas doesn't bail out

print $pal_fd "\000\000\000" x ($bpp - $pal_used + 1);


close $pal_fd;
close $scr_fd;
rename $pal_tmp, $pal_final;
rename $scr_tmp, $scr_final;

print "Written: $scr_final and $pal_final.\n";
print "Done, used $pal_used / $bpp colors in palette.\n";
