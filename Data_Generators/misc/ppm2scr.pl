#!/usr/bin/perl
# Matija Nalis <mnalis-git@voyager.hr>, GPLv3+ started 2020/08
# converts standard binary P6 ppm(5) image to  TEMP/*.scr + TEMP/*.pal format used by quickloadscreen() 

use strict;
use warnings;
use autodie qw/:all/;

my $basename = $ARGV[0];
my $ppm_name = $basename;

if (!defined $ppm_name) {
  print "Usage: $0 <BASENAME.ppm>\n";
  print "Converts PPM file to Ironseed 320x200 BASENAME.scr and BASENAME.pal files\n";
}

die "$basename does not look like .ppm file" unless $basename =~ s{\.ppm$}{}i;

my $pal_final = $basename . '.pal';
my $scr_final = $basename . '.scr';
my $pal_tmp = $pal_final . '.tmp';
my $scr_tmp = $scr_final . '.tmp';


open my $ppm_fd, '<', $ppm_name;

# FIXME: should support PPM comments, different whitespace etc. see ppm(5)
my $format = <$ppm_fd>; chomp $format;
die "ERROR: P6 PPM file needed, not $format" unless $format eq 'P6';
my ($height, $width) = split ' ', <$ppm_fd>;
die "ERROR: not 320x200 PPM file" unless $height==320 and $width==200;
my $bpp = <$ppm_fd>; chomp($bpp);
die "ERROR: must have 255 colors" unless $bpp==255;

undef $/; 	# slurp the rest of the file in one go
my @SCR = unpack "C*", <$ppm_fd>;
my %PALLETE = ();
my $pal_used = 0;

open my $pal_fd, '>', $pal_tmp;
open my $scr_fd, '>', $scr_tmp;

for (my $i = 0; $i < $height * $width * 3; $i+=3) {
  my $r = $SCR[$i]; 
  my $g = $SCR[$i+1];
  my $b = $SCR[$i+2];
  my $pal_idx = "$r:$g:$b";
  my $val = $PALLETE{$pal_idx};
  
  if (!defined $val) {		# add new entry to pallete
     $val = $pal_used++;
     die "ERROR: pallete overflow: $pal_used" if $val > $bpp;
     $PALLETE{$pal_idx} = $val;
     print $pal_fd chr($r).chr($g).chr($b);
  }
  
  print $scr_fd chr($val);
}

print $pal_fd "\000\000\000" x ($bpp - $pal_used + 1);


close $pal_fd;
close $scr_fd;
rename $pal_tmp, $pal_final;
rename $scr_tmp, $scr_final;

print "Done, used $pal_used / $bpp colors in pallete.\n";

