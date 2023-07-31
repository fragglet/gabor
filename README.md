This is a collection of code written by Berczi Gabor, who did a bunch
of fantastic work years ago documenting the DOS interfaces to Windows 9x's
network interfaces.

This is mirrored [from Rich Dawe's site](https://rich.phekda.org/gabor/).

Subdirectories here:

* [freesock](freesock/) - Berczi's sockets API that supports almost every
  DOS TCP/IP stack and is a fantastic source of documentation (even if
  in the form of code) for a lot of these APIs for which public
  documentation is sparse.

* [vslsocks](vslsocks/) - Pascal interface to the Virtual Socket Library

* [ws2dos](ws2dos/) - Pascal interface to the WSOCK2.VXD driver included
  in Windows 98. This is the closest thing that exists to documentation
  for the driver, and there's also information about the bugs that exist
  in the driver and how to work around them.

* [wsockvdd](wsockvdd/) - Berczi's driver that emulates the WSOCK.VXD interface
  on Windows NT.

