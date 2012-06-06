#!/bin/bash

# Adding support to build kernel

if [ $1 == "kernel" ]; then
	echo 'Will now start building kernel'
	export CROSS_COMPILE=/home/vishwanath/Documents/Files/myB2G/prebuilt/linux-x86/toolchain/arm-eabi-4.4.3/bin/arm-eabi-

	cd kernel &&
	make clean &&
	make ARCH=arm cyanogen_u8150_defconfig &&
	make ARCH=arm Image &&
	make ARCH=arm modules 

	echo 'Copying Image to device directory'
	cp ./kernel/arch/arm/boot/Image ./device/huawei/ideos/kernel
	chmod 776 device/huawei/ideos/kernel
	echo 'Kernel image created'
	exit $?	
fi

. setup.sh &&
time nice -n19 make $MAKE_FLAGS $@

ret=$?
echo -ne \\a
if [ $ret -ne 0 ]; then
	echo
	echo \> Build failed\! \<
	echo
	echo Build with \|./build.sh -j1\| for better messages
	echo If all else fails, use \|rm -rf objdir-gecko\| to clobber gecko and \|rm -rf out\| to clobber everything else.
else
	if echo $DEVICE | grep generic > /dev/null ; then
		echo Run \|./run-emulator.sh\| to start the emulator
		exit 0
	fi
	case "$1" in
	"gecko")
		echo Run \|./flash.sh gecko\| to update gecko
		;;
	*)
		echo Run \|./flash.sh\| to flash all partitions of your device
		;;
	esac
	exit 0
fi

exit $ret
