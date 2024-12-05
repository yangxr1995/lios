# 适用于Linux
qemu-system-i386 -m 128M -drive file=../../image/disk.img,index=0,media=disk,format=raw  -S -s -nographic&>/dev/null &
