# Compile rock on windows
1. Install [Git](https://git-for-windows.github.io/)
2. Install [MinGW](http://mingw.org/) in a path with no spaces in it
3. Install [make](http://gnuwin32.sourceforge.net/packages/make.htm) in a path with no spaces in it
4. Install the following packages from MinGW Installation manager found in basic setup:
  - mingw-developer-tool
  - mingw32-base
  - mingw32-gcc-g++
  - mingw32-gcc-objc
  - msys-base
5. Also install the package mingw32-phtreads-w32 from MinGW Installation manager found in All Packages/MinGW
6. Add gnuwin32/bin and mingw/bin to the environment variable path
7. Install msys2 32-bit version and follow the instructions on [this page](http://sourceforge.net/p/msys2/wiki/MSYS2%20installation/)
8. Start msys2 and install the following packages (see instructions [here](http://sourceforge.net/p/msys2/wiki/MSYS2%20installation/))
  - msys/wget
  - msys/tar
  - mingw32/mingw-w64-i686-libwinpthread-git
  - mingw32/mingw-w64-i686-winpthreads-git
  - msys/mingw-w64-cross-winpthreads-git
9. Run ```git clone https://github.com/fasterthanlime/rock```
10. Step into the folder rock and rund ```make rescue```
11. A working rock complier should now be available in rock/bin/

### Sources
https://amos.me/blog/2012/game-distrib/#setting-up-your-dev-environment

https://groups.google.com/forum/#!searchin/ooc-lang/compile$20bufferiterator/ooc-lang/7BgtQg7dI_0/lejRiBYfXjAJ

https://ooc-lang.org/install/
