#!/bin/bash
##
#  Copyright (C) 2015, Samsung Electronics, Co., Ltd.
#  Written by System S/W Group, S/W Platform R&D Team,
#  Mobile Communication Division.
#
#  Edited by Nguyen Tuan Quyen (koquantam)
##

set -e -o pipefail

PLATFORM=sc8830
DEFCONFIG=grandprimeve3g-dt_defconfig
NAME=CORE_kernel
VERSION=v3.0

export ARCH=arm
export LOCALVERSION=-${VERSION}

KERNEL_PATH=$(pwd)
KERNEL_ZIP=${KERNEL_PATH}/kernel_zip
KERNEL_ZIP_NAME=${NAME}_${VERSION}.zip
KERNEL_IMAGE=${KERNEL_ZIP}/tools/zImage
DT_IMG=${KERNEL_ZIP}/tools/dt.img
EXTERNAL_MODULE_PATH=${KERNEL_PATH}/external_module

JOBS=`grep processor /proc/cpuinfo | wc -l`

# Colors
cyan='\033[0;36m'
yellow='\033[0;33m'
red='\033[0;31m'
nocol='\033[0m'

function build() {
	clear;

	BUILD_START=$(date +"%s");
	echo -e "$cyan"
	echo "***********************************************";
	echo "              Compiling CORE(TM) kernel          	     ";
	echo -e "***********************************************$nocol";
	echo -e "$red";
	echo -e "Initializing defconfig...$nocol";
	make ${DEFCONFIG};
	echo -e "$red";
	echo -e "Building kernel...$nocol";
	make -j${JOBS};
	make -j${JOBS} dtbs;
	./scripts/mkdtimg.sh -i ${KERNEL_PATH}/arch/arm/boot/dts/ -o dt.img;
	find ${KERNEL_PATH} -name "zImage" -exec mv -f {} ${KERNEL_ZIP}/tools \;
	find ${KERNEL_PATH} -name "dt.img" -exec mv -f {} ${KERNEL_ZIP}/tools \;

	BUILD_END=$(date +"%s");
	DIFF=$(($BUILD_END - $BUILD_START));
	echo -e "$yellow";
	echo -e "Build completed in $(($DIFF / 60)) minute(s) and $(($DIFF % 60)) seconds.$nocol";
}

function make_zip() {
	echo -e "$red";
	echo -e "Making flashable zip...$nocol";

	cd ${KERNEL_PATH}/kernel_zip;
	zip -r ${KERNEL_ZIP_NAME} ./;
	mv ${KERNEL_ZIP_NAME} ${KERNEL_PATH};
}

function clean() {
	echo -e "$red";
	echo -e "Cleaning build environment...$nocol";
	make mrproper;

	if [ -e ${KERNEL_ZIP_NAME} ]; then
		rm ${KERNEL_ZIP_NAME};
	fi;

	if [ -e ${KERNEL_IMAGE} ]; then
		rm ${KERNEL_IMAGE};
	fi;

	if [ -e ${DT_IMG} ]; then
		rm ${DT_IMG};
	fi;

	echo -e "$yellow";
	echo -e "Done!$nocol";
}

function main() {
	reset;
	read -p "Please specify Toolchain path: " tcpath;
	if [ "${tcpath}" == "" ]; then
		echo -e "$red"
		export CROSS_COMPILE=/home/Remilia/toolchain/linaro-6.2/bin/arm-eabi-;
		echo -e "No toolchain path found. Using default local one:$nocol ${CROSS_COMPILE}";
	else
		export CROSS_COMPILE=${tcpath};
		echo -e "$red";
		echo -e "Specified toolchain path: $nocol ${CROSS_COMPILE}";
	fi;
	if [ "${USE_CCACHE}" == 1 ]; then
		if [ -e $(which ccache) ]; then
			CCACHE_PATH=$(which ccache | head -1);
			export CROSS_COMPILE="${CCACHE_PATH} ${CROSS_COMPILE}";
			export JOBS=16;
			echo -e "$red";
			echo -e "You have installed ccache, now using it...$nocol";
		else
			echo -e "$red";
			echo -e "You haven't installed ccache. Please installing by using *sudo apt-get install ccache*"
			echo -e "Exiting...$nocol"
			exit 1;
		fi;
	fi;

	echo -e "***************************************************************";
	echo "      CORE(TM) kernel for Samsung Galaxy Grand Prime SM-G531H";
	echo -e "***************************************************************";
	echo "Choices:";
	echo "1. Cleanup source";
	echo "2. Build kernel";
	echo "3. Build kernel then make flashable ZIP";
	echo "4. Make flashable ZIP package";
	echo "Leave empty to exit this script (it'll show invalid choice)";

	read -n 1 -p "Select your choice: " -s choice;
	case ${choice} in
		1) clean;;
		2) build;;
		3) build
		   make_zip;;
		4) make_zip;;
		*) echo
		   echo "Invalid choice entered. Exiting..."
		   sleep 2;
		   exit 1;;
	esac
}

main $@
