#! /bin/sh

SRC=contents
BB=busybox

TOOLS=""
#TOOLS="mdadm cryptsetup lvm"

# check prerequisites
if [[ $(objdump -p $(which $BB) | grep NEEDED | wc -l) -ne 0 ]]
then
	echo "ERROR: $BB is not available or is not a static executable"
	exit 1
fi

function create_init {
cat << EOF > $SRC/init
#!/bin/$BB sh
exec sh
EOF
return 0
}

function include_tool {
	echo "Including $1"
	cp -v --parents $(which $1) $SRC/
	for lib in `ldd $(which $1) | cut -d'>' -f2 | awk '{print $1}'` ; do
		if [ -f "$lib" ] ; then
			cp -v --parents $lib $SRC
		fi
	done
}

# populate with files
rm -Rf $SRC && \
mkdir -p $SRC && \
cp -v --parents $(which $BB) $SRC && \
ln -s $BB $SRC/bin/sh && \
create_init && \
chmod +x $SRC/init && \
for T in $(echo $TOOLS); do include_tool $T; done

# create iniramfs
if [[ $? -eq 0 ]]
then
	cd $SRC
	echo "Generating initramfs archive"
	find . -print0 | cpio --null -ov --format=newc | gzip > $OLDPWD/initramfs.cpio.gz
	cd $OLDPWD
fi

