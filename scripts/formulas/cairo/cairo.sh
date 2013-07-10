#! /bin/bash
#
# Cairo
# 2D graphics library with support for multiple output devices
# http://www.cairographics.org/
#
# has an autotools build system and requires pkg-config, libpng, & pixman,
# dependencies have their own formulas in cairo/depends
#
# references: http://www.cairographics.org/end_to_end_build_for_mac_os_x/

FORMULA_TYPES=( "osx" "vs2010" "win_cb" )

VER=1.12.14

# download the source code and unpack it into LIB_NAME
function download() {
	curl -LO http://cairographics.org/releases/cairo-$VER.tar.xz
	tar -xf cairo-$VER.tar.xz
	mv cairo-$VER cairo
	rm cairo-$VER.tar.xz
}

# executed inside the build dir
function build() {

	# build dependencies and install into $BUILD_DIR/cairo/build
	local buildDir=$(pwd)/apothecary-build
	mkdir -p $buildDir
	rm -rf $buildDir/bin $buildDir/lib $buildDir/share
	
	# build a custom version of pkg-config
	$APOTHECARY_DIR/apothecary -t $TYPE -a $ARCH -b $buildDir update $FORMULA_DIR/depends/pkg-config.sh
	export PKG_CONFIG=$buildDir/bin/pkg-config
	export PKG_CONFIG_PATH=$buildDir/lib/pkgconfig

	# set flags for osx 32 & 64 bit fat lib
	if [ "$TYPE" == "osx" ] ; then
		export MACOSX_DEPLOYMENT_TARGET=$OSX_MIN_SDK_VER
   		export LDFLAGS="-arch i386 -arch x86_64 -isysroot $XCODE_DEV_ROOT/Platforms/MacOSX.platform/Developer/SDKs/MacOSX$OSX_SDK_VER.sdk"
   		export CFLAGS="-Os -arch i386 -arch x86_64 -isysroot $XCODE_DEV_ROOT/Platforms/MacOSX.platform/Developer/SDKs/MacOSX$OSX_SDK_VER.sdk"
	
	elif [ "$TYPE" == "vs2010" ] ; then
		echoWarning "TODO: vs2010 build settings here?"
	
	elif [ "$YTYPE" == "win_cb" ] ; then
		echoWarning "TODO: win_cb build settings here?"
	fi

	# build and install dependencies (some commented for now as they might be needed for other platforms)
	#$APOTHECARY_DIR/apothecary -t $TYPE -a $ARCH -b $buildDir update $FORMULA_DIR/depends/zlib.sh
	$APOTHECARY_DIR/apothecary -t $TYPE -a $ARCH -b $buildDir update $FORMULA_DIR/depends/libpng.sh
	$APOTHECARY_DIR/apothecary -t $TYPE -a $ARCH -b $buildDir update $FORMULA_DIR/depends/pixman.sh
	#$APOTHECARY_DIR/apothecary -t $TYPE -a $ARCH -b $buildDir update freetype

	# build cairo
	./configure --prefix=$buildDir --disable-dependency-tracking --disable-xlib --disable-ft
	make install

	# clean up env vars
	unset PKG_CONFIG PKG_CONFIG_PATH CFLAGS LDFLAGS MACOSX_DEPLOYMENT_TARGET
}

# executed inside the lib src dir, first arg $1 is the dest libs dir root
function copy() {
	
	cd apothecary-build

	# headers
	mkdir -p $1/include
	cp -Rv include/* $1/include

	# lib
	mkdir -p $1/lib/$TYPE
	if [ "$TYPE" == "vs2010" ] ; then
		echoWarning "copy vs2010 lib"

	elif [ "$TYPE" == "osx" -o "$TYPE" == "win_cb" ] ; then
		if [ "$TYPE" == "osx" ] ; then
			cp -v lib/libcairo-script-interpreter.a $1/lib/$TYPE/cairo-script-interpreter.a
		fi
		cp -v lib/libcairo.a $1/lib/$TYPE/cairo.a
		cp -v lib/libpixman-1.a $1/lib/$TYPE/pixman-1.a
	fi
}
