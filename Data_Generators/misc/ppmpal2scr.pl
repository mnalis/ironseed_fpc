#!/usr/bin/perl
# Matija Nalis <mnalis-git@voyager.hr>, GPLv3+ started 2020/09
# converts standard binary P6 ppm(5) image and specified .PAL file  to  TEMP/*.scr format used by quickloadscreen() 

use strict;
use warnings;
use autodie qw/:all/;

my $COLOR_FACTOR=4;	# game seems to be using <<2, which is *4

my $basename = $ARGV[0];
my $pal_name = $ARGV[1];
my $ppm_name = $basename;
my $want_width = $ENV{WIDTH} || 320;
my $want_height = $ENV{HEIGHT} || 200;

if (!defined $ppm_name or !defined $pal_name) {
  print "Usage: $0 <BASENAME.ppm> <main.pal>\n";
  print "Converts PPM file to Ironseed 320x200 (or other specified size via ENV)  BASENAME.scr using main.pal for existing pallete\n";
  exit 1;
}

die "$basename does not look like .ppm file" unless $basename =~ s{\.ppm$}{}i;

my $scr_final = $basename . '.scr';
my $scr_tmp = $scr_final . '.tmp';


open my $ppm_fd, '<', $ppm_name;

# FIXME: should support PPM comments, different whitespace etc. see ppm(5)
my $format = <$ppm_fd>; chomp $format;
die "ERROR: P6 PPM file needed, not $format" unless $format eq 'P6';
my ($width, $height) = split ' ', <$ppm_fd>;
die "ERROR: not ${want_width}x${want_height} PPM file" unless $width==$want_width and $height==$want_height;
my $bpp = <$ppm_fd>; chomp($bpp);
die "ERROR: must have 255 colors" unless $bpp==255;

undef $/; 	# slurp the rest of the file in one go
my @SCR = unpack "C*", <$ppm_fd>;

# read in pallete to %PALLETE
my %PALLETE = ();

open my $pal_fd, '<', $pal_name;
my @_pal = unpack "C*", <$pal_fd>;
close $pal_fd;

for (my $pal_used=0; $pal_used < 768; $pal_used+=3) {
  my $r = $_pal[$pal_used];
  my $g = $_pal[$pal_used+1];
  my $b = $_pal[$pal_used+2];
  my $pal_idx = "$r:$g:$b";
  $PALLETE{$pal_idx} = int($pal_used / 3) if !defined $PALLETE{$pal_idx};
}

# write to SCR
open my $scr_fd, '>', $scr_tmp;

for (my $i = 0; $i < $width * $height * 3; $i+=3) {
  my $r = int($SCR[$i] / $COLOR_FACTOR);
  my $g = int($SCR[$i+1] / $COLOR_FACTOR);
  my $b = int($SCR[$i+2] / $COLOR_FACTOR);
  my $pal_idx = "$r:$g:$b";
  my $val = $PALLETE{$pal_idx};

  if (!defined $val) {		# entry not in pallete
     #use Data::Dumper;
     #print Dumper(%PALLETE);
     die "invalid RGB: $pal_idx not found in $pal_name at idx: $i";
  }

  print $scr_fd chr($val);
}

close $scr_fd;
rename $scr_tmp, $scr_final;

print "Written: $scr_final.\n";
