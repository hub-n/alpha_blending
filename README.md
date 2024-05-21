# Author:
Hubert Niewierowicz

# Description:
The program, written in the RISC-V assembly language,
takes in two bmp files and 'blends' the second file onto the first one.
It reads the file headers (assuming the most common 54 byte header size)
and dynamically allocates heap memory for the pixel array. It then parses
through the pixels and blends each one with a proportion of 50:50.
BMP files of various and different sizes are supported, although they
obviously must have an alpha channel (32 bpp).
To reset the images use 'make'.
