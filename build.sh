#! /bin/sh

SRC=contents
BB=busybox

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

rm -Rf $SRC && \
mkdir -p $SRC/bin && \
cp $(which $BB) $SRC/bin && \
ln -s $BB $SRC/bin/sh && \
create_init && \
chmod +x $SRC/init

if [[ $? -eq 0 ]]
then
	cd $SRC
	find . -print0 | cpio --null -ov --format=newc | gzip > $OLDPWD/initramfs.cpio.gz
	cd $OLDPWD
fi

