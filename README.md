# MPackerX
MPackerX v2 - Mac OS X GUI for my bitmap compression tool

I made the MPackerX GUI version in Xcode/swift 4.2 as helloworld app (my first Mac OS X app) for experimenting.
The primary goal was to make it quick and easy to use (at least for me) packaging tool for my game remaking project.

MPackerX is my own compression/decompression algorythm for small bitmap images. It works well on vintage machines, have an ultra small footprint (decomression routine in 68k assembly is only 188 bytes for the "9o" version and 262 bytes for the "X" version) and low memory usage (only needs space for the decompressed data). The 68k ASM decompression routine is included in the [MPackerX commandline tool](https://github.com/AbelVincze/MPackerX-commandline) repository

Features of the app:
- open and decompresses .pkx (MPackerX compressed) files
- open any binary file (max 64KB is loaded)
- compress, with customizable compression settings
- visualize loaded/compressed data
- Import and Export hexdumps in multiple formats (easy cooperation with source files)
- Reorder data (help organize byte order for target platform, or improve compression ratio)
- Crop data (to allow opening container files like .pbm, or reuse just a portion of the original bitmap image)
- Append file (to join multiple graphic elements into one file)

The source files was made using Xcode 10 and swift 4.2 language, the complied executable runs on Mac OS X 10.9 or later versions.

Future ideas for developing:
- Opening image files and convert them to bitmap image
- colored bitmap image support
- batch compress/decompress files
- selectable preview container size (16x2048, 32x1024, 64x512, 128x256)

MPackerX enhancements:
- support larger files than 64KB
- automatically find the best compression setting

No sense ideas:
- Making GUI app for Mac OS 7 in 68k Assembly
- Making C64 version (decompression tool in 6510 Assembly is already done)
