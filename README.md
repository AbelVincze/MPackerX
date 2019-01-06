# MPackerX
MPackerX v2 - Mac OS X GUI for my bitmap compression tool

I made the MPackerX GUI version in Xcode/swift 4.2 as helloworld app (my first Mac OS X app) for experimenting.
The primary goal was to make it quick and easy to use (for me) packaging tool for my game remaking project.

MPackerX is my own compression/decompression algorythm for small bitmap images. It works well on vintage machines, have an ultra small footprint (decomression routine in 68k assembly is only 188 bytes for the "9o" version and 262 bytes for the "X" version) and low memory usage (only needs space for the decompressed data). The 68k ASM decompression routine is included in the [MPackerX commandline tool](https://github.com/AbelVincze/MPackerX-commandline) repository

Features of the app:
- open and decompresses .pkx (MPackerX compressed) files
- open any binary file (max 64KB is loaded)
- compress, with various comression setting
- visualize loaded/compressed data
- Import and Export hexdumps (easy integration in source files)
- Reorder data (helps organize byte order for target platform, or improve compression ration)
- Crop data
- Append file (to join multiple graphic elements into one data file)

The source files was made using Xcode 10 and swift 4.2 language, the complied executable runs on Mac OS X 10.9 or later versions.
