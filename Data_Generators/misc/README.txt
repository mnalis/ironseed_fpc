Image conversion programs for Ironseed:

- .scr and .pal
  TEMP/*.scr + TEMP/*.pal (uncompressed 320x200 256-color images, with pallete files)
  created/loaded by quicksavescreen() and quickloadscreen()

- .cpr 
  data/*.cpr, TEMP/*.cpr (compressed 320x200 images used by game)

- .ppm
  standard interchanged format, can be P6 (binary) or P3 (ASCII) - see ppm(5) manual page for more info

- icons.vga (and main.pal PALLETE)
  81 icons of 17x15 pixels

Quick HOWTO:

- convert "foobar.cpr" to "foobar.png"
  cpr2scr foobar 				# creates foobar.scr and foobar.pal from foobar.cpr
  scr2ppm.pl foobar.scr foobar.pal		# creates foobar.ppm from foobar.scr and foobar.pal
  convert -gamma 1.2 -resize 200% foobar.ppm foobar.png		# example ImageMagick6 coversion with color correction and size increase

- convert "barbaz.png" to "barbaz.cpr"
  convert barbaz.png barbaz.ppm			# creates barbaz.ppm in P6 PPM binary format from barbaz.png
  ppm2scr.pl barbaz.ppm				# creates barbaz.scr and barbaz.pal from barbaz.ppm
  scr2cpr barbaz				# creates barbaz.cpr from barbaz.scr and barbaz.pal

- convert "icons.vga" and "main.pal" to "icons.png"
  icons2ppm.pl data/icons.vga data/main.pal | convert - Graphics_Assets/icons.png

- convert "icons.png" to "icons.vga" using aux. "main.pal"
  convert Graphics_Assets/icons.png ppm:- | Data_Generators/misc/ppm2icons.pl data/main.pal > data/icons.vga
