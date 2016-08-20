# Some configuration options
#----------------------------

# Any extra options you need
CFLAGS=-I/usr/include/GraphicsMagick -Wall -g -fno-strict-aliasing -O2 -pthread -L/usr/lib -L/usr/lib/X11 -L/usr/lib -L/usr/lib -lGraphicsMagick++ -lGraphicsMagick -ljbig -llcms2 -ltiff -lfreetype -ljasper -ljpeg -lpng12 -lwmflite -lXext -lSM -lICE -lX11 -llzma -lbz2 -lxml2 -lz -lm -lgomp -lpthread
CFLAGS+=-std=c++11

ifneq (${CC},clang)
CFLAGS+=-fpeel-loops
endif

EXTRADEFS=

# Graphics library to use, can be GD or ImageMagick.
IMG_LIB=GD
#IMG_LIB=ImageMagick

# In simple mode, by default all data needed for queries is now
# read into memory, using in total about 500 bytes per image. It
# is possible to select a disk cache using mmap for this instead.
# Then the kernel can read this memory into the filecache or
# discard it as needed. The app uses as little memory as possible
# but depending on IO load queries can take longer (sometimes a lot).
# This option is especially useful for a VPS with little memory.
# override DEFS+=-DUSE_DISK_CACHE

# If you do not have any databases created by previous versions of
# this software, you can uncomment this to not compile in code for
# upgrading old versions (use iqdb rehash <dbfile> to upgrade).
override DEFS+=-DNO_SUPPORT_OLD_VER

# Enable a significantly less memory intensive but slightly slower
# method of storing the image index internally (in simple mode).
override DEFS+=-DUSE_DELTA_QUEUE

# This may help or hurt performance. Try it and see for yourself.
override DEFS+=-fomit-frame-pointer

# Force use of a platform independent 64-bit database format.
override DEFS+=-DFORCE_64BIT

# -------------------------
#  no configuration below
# -------------------------

.SUFFIXES:

all:	iqdb

%.o : %.h
%.o : %.cpp
iqdb.o : imgdb.h haar.h auto_clean.h debug.h
imgdb.o : imgdb.h imglib.h haar.h auto_clean.h delta_queue.h debug.h
test-db.o : imgdb.h delta_queue.h debug.h
haar.o :
%.le.o : %.h
iqdb.le.o : imgdb.h haar.h auto_clean.h debug.h
imgdb.le.o : imgdb.h imglib.h haar.h auto_clean.h delta_queue.h debug.h
haar.le.o :

.ALWAYS:

ifeq (${IMG_LIB},GD)
IMG_libs = -lgd $(shell gdlib-config --ldflags; gdlib-config --libs)
IMG_flags = $(shell gdlib-config --cflags)
IMG_objs = resizer.o
override DEFS+=-DLIB_GD
else
ifeq (${IMG_LIB}, ImageMagick)
IMG_libs = $(shell pkg-config --libs ImageMagick)
IMG_flags = $(shell pkg-config --cflags ImageMagick)
IMG_objs =
override DEFS+=-DLIB_ImageMagick
else
$(error Unsupported image library '${IMG_LIB}' selected.)
endif
endif

% : %.o haar.o imgdb.o debug.o ${IMG_objs} # bloom_filter.o
	g++ -o $@ $^ ${CFLAGS} ${LDFLAGS} ${IMG_libs} ${DEFS} ${EXTRADEFS}

%.le : %.le.o haar.le.o imgdb.le.o debug.le.o ${IMG_objs} # bloom_filter.le.o
	g++ -o $@ $^ ${CFLAGS} ${LDFLAGS} ${IMG_libs} ${DEFS} ${EXTRADEFS}

test-resizer : test-resizer.o resizer.o debug.o
	g++ -o $@ $^ ${CFLAGS} ${LDFLAGS} -g -lgd -ljpeg -lpng ${DEFS} ${EXTRADEFS} `gdlib-config --ldflags`

%.o : %.cpp
	g++ -c -o $@ $< -O2 ${CFLAGS} -DNDEBUG -Wall -DLinuxBuild -g ${IMG_flags} ${DEFS} ${EXTRADEFS}

%.le.o : %.cpp
	g++ -c -o $@ $< -O2 ${CFLAGS} -DCONV_LE -DNDEBUG -Wall -DLinuxBuild -g ${IMG_flags} ${DEFS} ${EXTRADEFS}

%.S:	.ALWAYS
	g++ -S -o $@ $*.cpp -O2 ${CFLAGS} -DNDEBUG -Wall -DLinuxBuild -g ${IMG_flags} ${DEFS} ${EXTRADEFS}

clean:
	rm -f *.o iqdb
