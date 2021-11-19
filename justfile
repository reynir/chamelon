image := "_build/default/src/test.img"
HOME := env_var("HOME")

block_size := "4096"
program_block_size := "16"

test_img:
	dune build @default
	dd if=/dev/zero of={{image}} bs=64K count=1
	_build/default/src/format.exe {{image}}

read: test_img mount
	sudo mkdir /mnt/lib
	sudo cp lib/block.ml /mnt/lib
	_build/default/src/lfs_read.exe {{image}} {{block_size}} lib/block.ml

readmdir BLOCK:
	readmdir.py -a --log {{image}} {{block_size}} {{BLOCK}}

readtree:
	readtree.py -a --log {{image}} {{block_size}} 0 1

mklittlefs-list:
	mklittlefs -d 5 -p {{program_block_size}} -b {{block_size}} -l {{image}}

umount:
	sudo umount -q /mnt || true
	sudo losetup -d /dev/loop0 || true
	sudo rm -r /mnt/* || true

mount: umount
	sudo losetup /dev/loop0 {{image}}
	sudo chmod a+rw /dev/loop0
	sudo {{HOME}}/fuse-littlefs/lfs --block_size={{block_size}} -s /dev/loop0 /mnt
	# nb: `ls /mnt` will fail if there are no files at all in the filesystem.

fuse-format:
	dd if=/dev/zero of={{image}} bs=64K count=1
	sudo umount -q /mnt || true
	sudo losetup -d /dev/loop0 || true
	sudo losetup /dev/loop0 {{image}}
	sudo {{HOME}} fuse-littlefs/lfs --block_size={{block_size}} --format /dev/loop0

hexdump:
	xxd {{image}} | less
