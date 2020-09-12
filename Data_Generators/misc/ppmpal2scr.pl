#!/usr/bin/perl
# Matija Nalis <mnalis-git@voyager.hr>, GPLv3+ started 2020/09
# converts standard binary P6 ppm(5) image and specified .PAL file  to  TEMP/*.scr format used by quickloadscreen() 

use strict;
use warnings;
use autodie qw/:all/;

my $COLOR_FACTOR = $ENV{COLORF} || 4;	# game seems to be using <<2, which is *4

my $basename = $ARGV[0];
my $pal_name = $ARGV[1];
my $is_update = (defined $ARGV[2]) && ($ARGV[2] eq 'UPDATE');
my $ppm_name = $basename;
my $want_width = $ENV{WIDTH} || 320;
my $want_height = $ENV{HEIGHT} || 200;

if (!defined $ppm_name or !defined $pal_name) {
  print "Usage: $0 <BASENAME.ppm> <main.pal> [UPDATE]\n";
  print "Converts PPM file to Ironseed 320x200 (or other specified size via ENV)  BASENAME.scr using main.pal for existing pallete\n";
  print "if 'UPDATE' is specified, the main.pal will be filled with extra pallete entries if needed\n";
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

open my $pal_fd, $is_update? '+<' : '<', $pal_name;
my @_pal = unpack "C*", <$pal_fd>;

my $pal_orig_max = scalar @_pal;
for (my $pal_used=0; $pal_used < $pal_orig_max; $pal_used+=3) {
  my $r = $_pal[$pal_used];
  my $g = $_pal[$pal_used+1];
  my $b = $_pal[$pal_used+2];
  my $pal_idx = "$r:$g:$b";
  $PALLETE{$pal_idx} = int($pal_used / 3) if !defined $PALLETE{$pal_idx};
}

my $pal_used = $pal_orig_max / 3;

# write to SCR
open my $scr_fd, '>', $scr_tmp;

my $remains=64000;
for (my $i = 0; $i < $width * $height * 3; $i+=3) {
  my $r = int($SCR[$i] / $COLOR_FACTOR);
  my $g = int($SCR[$i+1] / $COLOR_FACTOR);
  my $b = int($SCR[$i+2] / $COLOR_FACTOR);
  my $pal_idx = "$r:$g:$b";
  my $val = $PALLETE{$pal_idx};

  if (!defined $val) {		# entry not in pallete
     if ($is_update) {
       $val = $pal_used++;
       die "ERROR: pallete overflow: $pal_used" if $val > $bpp;
       $PALLETE{$pal_idx} = $val;
       print $pal_fd chr($r).chr($g).chr($b);
     } else {
       #use Data::Dumper;
       #print Dumper(\%PALLETE);
       die "invalid RGB: $pal_idx not found in $pal_name at idx: $i, and UPDATE not specified";
     }
  }

  print $scr_fd chr($val);
  $remains--;
}

if ($is_update) {
  print $pal_fd "\000\000\000" x ($bpp - $pal_used + 1);
}
close $pal_fd;

print $scr_fd chr(0) x $remains;	# fillup so scr2cpr.pas doesn't bail out

close $scr_fd;
rename $scr_tmp, $scr_final;

print "Written: $scr_final" . ($is_update ? " and $pal_name ($pal_used/$bpp).\n" : ".\n");
