BUILD_DATE=$(date "+%Y%m%d-%H%M")

#ccache
export CCACHE_DIR="$HOME/.cache/ccache_mikernel"
echo "CCACHE_DIR: [$CCACHE_DIR]"

MAKE_ARGS=(
    ARCH=arm64
	SUBARCH=arm64
	O=out
	"CC=ccache clang"
	"CXX=ccache clang++"
	CROSS_COMPILE=aarch64-linux-gnu-
	CROSS_COMPILE_ARM32=arm-linux-gnueabi-
	CROSS_COMPILE_COMPAT=arm-linux-gnueabi-
	CLANG_TRIPLE=aarch64-linux-gnu-
	AR=llvm-ar
	NM=llvm-nm
	OBJCOPY=llvm-objcopy
	OBJDUMP=llvm-objdump
	STRIP=llvm-strip
	"HOSTCC=ccache clang"
	"HOSTCXX=ccache clang++"
	LD=ld.lld
	LLVM=1
	LLVM_IAS=0
)

local_version_str="-perf"
local_version_date_str="-UMPASS-$(date +%Y%m%d)"

KSU_ZIP_STR=noksu
if [ "$1" == "ksu" ]; then
    KSU_E=1
    KSU_ZIP_STR=ksu
else
    KSU_E=0
fi

rm -rf out/
rm -rf AnyKernel3/

#setting up AK
git clone https://github.com/liyafe1997/AnyKernel3 -b kona --single-branch --depth=1

if [ $KSU_E -eq 1 ]; then
    echo "Downloading KernelSU-Next"
    curl -LSs "https://raw.githubusercontent.com/KernelSU-Next/KernelSU-Next/next/kernel/setup.sh" | bash -
else 
    echo "Building without KernelSU-Next"
fi

#----------------------build stuff here

echo "======= START OF BUILD ======="
make "${MAKE_ARGS[@]}" cas_defconfig

sed -i "s/${local_version_str}/${local_version_date_str}/g" out/.config

if [ $KSU_E -eq 1 ]; then
		scripts/config --file out/.config -e KSU
	else
		scripts/config --file out/.config -d KSU
fi

make "${MAKE_ARGS[@]}" -j$(nproc --all)

echo "======= END OF BUILD ======="

ZIP_NAME="UMPASS-$(date "+%Y%m%d-%H%M").zip"
KOUT_PATH="/mnt/d/users/juan/kernels/cas/"

if [ -f "out/arch/arm64/boot/Image" ]; then
    echo "Image found. Build successful"
    cd AnyKernel3
	cp ../out/arch/arm64/boot/Image Image
	zip -r9 ../$ZIP_NAME -- *
	cd ..
	cp $ZIP_NAME $KOUT_PATH
	rm -rf $ZIP_NAME
else
    echo "Image not found. Build failed!"
    exit 1
fi

echo "======= CLEANING UP ======="

rm -rf KernelSU-Next/ && echo "  RM      KernelSU-Next"
rm -rf out/ && echo "  RM      out"
rm -rf AnyKernel3 && echo "  RM      AnyKernel3"
