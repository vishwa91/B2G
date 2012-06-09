#!/bin/bash

# Adding support to build kernel

if [[ "$1" == "kernel" ]]; then
	echo 'Will now start building kernel'
	export CROSS_COMPILE="$PWD"/prebuilt/linux-x86/toolchain/arm-eabi-4.4.3/bin/arm-eabi-

	cd kernel &&
	make ARCH=arm cyanogen_u8150_defconfig  -j10 &&
	make ARCH=arm zImage -j10 &&
	make ARCH=arm modules -j10

	echo 'Copying Image to device directory'
	cd ..
	cp ./kernel/arch/arm/boot/zImage ./device/huawei/u8150/kernel
	chmod 776 device/huawei/u8150/kernel
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
