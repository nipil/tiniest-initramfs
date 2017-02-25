#! /bin/bash

# directory structure
TEMPLATE=template
INITSCRIPTS=init-scripts
TARGET=contents

# contents variables
BB="busybox"
INIT="init-rescue-basic"
KVERSION="$(uname -r)"
KMODULES=""
TOOLS="$BB"

# handle command line arguments
while getopts ":k:m:t:i:" opt; do
	case $opt in
	i)
		INIT="$OPTARG"
		;;
	k)
		KVERSION="$OPTARG"
		;;
	m)
		KMODULES="$KMODULES $OPTARG"
		;;
	t)
		TOOLS="$TOOLS $OPTARG"
		;;
	\?)
		error "Invalid option: -$OPTARG"
		;;
	:)
		error "Option -$OPTARG requires an argument."
	;;
	esac
done

function info {
	echo "INFO: $1"
	return 0
}

function error {
	echo "$1" >&2
	exit 1
}

# display what will be done
info "Init script: $INIT"
info "Command line tools: $TOOLS"
info "Kernel modules: $KMODULES"
info "Kernel version: $KVERSION"

function include_tool {
	echo "Including tool $1"
	WHICH=$(which $1)
	[ $? -eq 0 ] || error "could not find full path for $1 (not in PATH)"
	cp -v --parents "$WHICH" $TARGET/
	[ $? -eq 0 ] || error "could not copy return $1"
	for lib in $(ldd "$WHICH" | cut -d'>' -f2 | awk '{print $1}') ; do
		if [ -f "$lib" ] ; then
			cp -v --parents $lib $TARGET
			[ $? -eq 0 ] || error "could not copy return $lib"
		fi
	done
	return 0
}

function include_tools {
	for T in $@
	do
		include_tool $T;
		[ $? -eq 0 ] || error "including tool $T failed"
	done
	return 0
}

function include_modules {
	[[ -n "$@" ]] || return 0
	for M in $@
	do
		info "Including module $M"
		MODINFO=$(modinfo -k $KVERSION $M)
		[ $? -eq 0 ] || error "error while getting info for module $M"
		MODFILE=$(echo "$MODINFO" | grep 'filename' | awk '{ print $2 }')
		cp -v --parents $MODFILE $TARGET/
		[ $? -eq 0 ] || error "including module $M failed"
		DEPS=$(echo "$MODINFO" | grep 'depends' | awk '{ print $2 }' | tr ',' ' ')
		include_modules $DEPS
		[ $? -eq 0 ] || error "including dependencies $DEPS failed"
	done
	cp -v --parents /lib/modules/$KVERSION/modules.* $TARGET/
	[ $? -eq 0 ] || error "failed to include module descriptions"
	return 0
}

function create_initramfs {
	cd $1
	info "Generating initramfs archive"
	find . -print0 | cpio --null -ov --format=newc | gzip > $OLDPWD/initramfs.cpio.gz
	RES=$?
	cd $OLDPWD
	return $RES
}

function prepare_target {
	rm -Rf $1
	[ $? -eq 0 ] || error "deleting $TARGET failed"
	mkdir -vp $1{,/bin}
	[ $? -eq 0 ] || error "creating $TARGET failed"
}

function minimal_setup {
	ln -sv /bin/$BB $TARGET/bin/sh
	[ $? -eq 0 ] || error "creating $BB symlink failed"
	cp $INITSCRIPTS/$1 $TARGET/init
	[ $? -eq 0 ] || error "copying init script $1 failed"
	chmod +x $TARGET/init
	[ $? -eq 0 ] || error "setting executable bit on init"
}

# do actual work

prepare_target "$TARGET" && \
minimal_setup "$INIT" && \
include_tools $TOOLS && \
include_modules $KMODULES && \
create_initramfs "$TARGET"

