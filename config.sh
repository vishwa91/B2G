#!/bin/bash

REPO=./repo

install_blobs() {
	mkdir -p download-$1 &&
	for BLOB in $2 ; do
		curl https://dl.google.com/dl/android/aosp/$BLOB -o download-$1/$BLOB -z download-$1/$BLOB &&
		tar xvfz download-$1/$BLOB -C download-$1
	done &&
	for BLOB_SH in download-$1/extract-*.sh ; do
		BASH_ENV=extract.rc bash $BLOB_SH
	done
}

repo_sync() {
	if [ "$GITREPO" = "$GIT_TEMP_REPO" ]; then
		BRANCH="master"
	else
		BRANCH=$1
	fi
	rm -rf .repo/manifest* &&
	$REPO init -u $GITREPO -b $BRANCH &&
	$REPO sync
	ret=$?
	if [ "$GITREPO" = "$GIT_TEMP_REPO" ]; then
		rm -rf $GIT_TEMP_REPO
	fi
	if [ $ret -ne 0 ]; then
		echo Repo sync failed
		exit -1
	fi
}

case `uname` in
"Darwin")
	CORE_COUNT=`system_profiler SPHardwareDataType | grep "Cores:" | sed -e 's/[ a-zA-Z:]*\([0-9]*\)/\1/'`
	;;
"Linux")
	CORE_COUNT=`grep processor /proc/cpuinfo | wc -l`
	;;
*)
	echo Unsupported platform: `uname`
	exit -1
esac

GIT_TEMP_REPO="tmp_manifest_repo"
if [ -n "$2" ]; then
	GITREPO=$GIT_TEMP_REPO
	GITBRANCH="master"
	rm -rf $GITREPO &&
	git init $GITREPO &&
	cp $2 $GITREPO/default.xml &&
	cd $GITREPO &&
	git add default.xml &&
	git commit -m "manifest" &&
	cd ..
else
	GITREPO="git://github.com/praveenv253/b2g-manifest"
fi

case "$1" in
"ideos")
	echo DEVICE=ideos > .config &&
	repo_sync ideos &&
	(cd device/huawei/ideos && ./extract-files.sh)
	;;

"galaxy-s2")
	echo DEVICE=galaxys2 > .config &&
	repo_sync galaxy-s2 &&
	(cd device/samsung/galaxys2 && ./extract-files.sh)
	;;

"galaxy-nexus")
	MAGURO_BLOBS="broadcom-maguro-imm76d-4ee51a8d.tgz
                      imgtec-maguro-imm76d-0f59ea74.tgz
                      samsung-maguro-imm76d-d16591cf.tgz"
	echo DEVICE=maguro > .config &&
	install_blobs galaxy-nexus "$MAGURO_BLOBS" &&
	repo_sync maguro
	;;

"nexus-s")
	CRESPO_BLOBS="akm-crespo-imm76d-8314bd5a.tgz
		      broadcom-crespo-imm76d-a794e660.tgz
		      imgtec-crespo-imm76d-d381b3bf.tgz
		      nxp-crespo-imm76d-d3862877.tgz
		      samsung-crespo-imm76d-d2d82200.tgz"
	echo DEVICE=crespo > .config &&
	install_blobs nexus-s "$CRESPO_BLOBS" &&
	repo_sync crespo
	;;

"otoro")
	echo DEVICE=otoro > .config &&
	repo_sync otoro &&
	(cd device/qcom/otoro && ./extract-files.sh)
	;;

"emulator")
	echo DEVICE=generic > .config &&
	echo LUNCH=full-eng >> .config &&
	repo_sync master
	;;

"emulator-x86")
	echo DEVICE=generic_x86 > .config &&
	echo LUNCH=full_x86-eng >> .config &&
	repo_sync master
	;;

*)
	echo Usage: $0 \(device name\)
	echo
	echo Valid devices to configure are:
	echo - ideos
	echo - galaxy-s2
	echo - galaxy-nexus
	echo - nexus-s
	echo - emulator
	echo - emulator-x86
	exit -1
	;;
esac

if [ $? -ne 0 ]; then
	echo Configuration failed
	exit -1
fi

echo MAKE_FLAGS=-j$((CORE_COUNT + 2)) >> .config
echo GECKO_OBJDIR=$PWD/objdir-gecko >> .config

echo Run \|./build.sh\| to start building
