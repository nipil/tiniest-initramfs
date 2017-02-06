# tiniest-initramfs

Tiniest working initramfs generator

# requires

- a static version of busybox available in path
- some standard utils : objdump, ldd, cpio, gzip

# build

	./build.sh

Info: you can add the TOOLS variable to add other programs (tested with mdadm, cryptsetup, and lvm)

Note: use sudo to get uid=gid=0 instead of current user ids

# test

- get a working kernel for your host
- qemu-system-* for you architecture

Run with QEmu :

	qemu-system-x86_64 -kernel kernel.img -initrd initramfs.cpio.gz

You should reach a busybox command prompt.

Note: If you exit, you get a kernel panic as init gets killed, which is normal

# what's next

Experience with it, add stuff to build script....

Guidelines about initramfs content for your next steps :

https://wiki.gentoo.org/wiki/Custom_Initramfs

Hope it helps

