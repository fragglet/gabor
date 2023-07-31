# WSOCKVDD - WSOCK.VXD Emulation for Windows NT

WSOCKVDD, Copyright (C) 1999 by [Berczi Gabor](mailto:sting@freemail.hu)
WSOCKVDD is distributed under the terms of the [GNU General Public
License](license.txt).

## Introduction

WSOCKVDD is a Virtual Device Driver (VDD) for Windows NT. It emulates the
interface provided by WSOCK.VXD. You load, unload and call it as you would
WSOCK.VXD. WSOCK.VXD is (mostly) documented in the [WSOCK.VXD
Pseudo-Documentation](https://www.richdawe.be/archive/dl/wsockvxd.htm).
Currently WSOCKVDD only supports a real-mode interface. This means any attempt
to obtain its entry point from protected-mode will fail.

