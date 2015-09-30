# Compile rock on windows
1. Install [Git](https://git-for-windows.github.io/)
1. Install [MinGW](http://mingw.org/) in a path with no spaces in it
1. Install [make](http://gnuwin32.sourceforge.net/packages/make.htm) in a path with no spaces in it
1. Install the following packages from MinGW Installation manager found in basic setup:
  - mingw-developer-tool
  - mingw32-base
  - mingw32-gcc-g++
  - mingw32-gcc-objc
  - msys-base
1. Also install the package mingw32-phtreads-w32 from MinGW Installation manager found in All Packages/MinGW
1. Add gnuwin32/bin and mingw/bin to the environment variable path
1. Install msys2 32-bit version and follow the instructions on [this page](https://msys2.github.io/)
1. Start msys2 and install the following packages with pacman.
  - msys/wget
  - msys/tar
  - mingw32/mingw-w64-i686-libwinpthread-git
  - mingw32/mingw-w64-i686-winpthreads-git
  - msys/mingw-w64-cross-winpthreads-git

  pacman -S package_name/package_group to install a package.

  pacman -R package_name/package_group to remove a pacakge.

  pacman -Ss name_pattern to search for a package.
1. Run ```git clone https://github.com/fasterthanlime/rock```
1. Step into the folder rock and run ```make rescue```
1. A working rock complier should now be available in rock/bin/

# Compile the cogneco version of rock
1. Follow the steps above
1. Run ```make backup```
1. Add cogneco as a remote ```git remote add cogneco https://github.com/cogneco/rock```
1. Fetch from and checkout the master branch from cogneco ```git fetch cogneco``` ```git checkout cogneco/master```
1. Run ```make safe```
1. A working cogneco version of the rock complier should now be available in rock/bin/

### Sources
https://amos.me/blog/2012/game-distrib/#setting-up-your-dev-environment

https://groups.google.com/forum/#!searchin/ooc-lang/compile$20bufferiterator/ooc-lang/7BgtQg7dI_0/lejRiBYfXjAJ

https://ooc-lang.org/install/
