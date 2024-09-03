#!/bin/bash
set -e

# Function to set output variables
set_output() {
    echo "$1=$2" >> $GITHUB_OUTPUT
}

# Install necessary packages
echo "Installing necessary packages..."
sudo apt-get update
sudo apt-get install -y aria2 git

# Clone OrangeFox scripts
echo "Cloning OrangeFox scripts..."
git clone https://gitlab.com/OrangeFox/misc/scripts.git
cd scripts
bash setup/android_build_env.sh

# Set up the build environment
MANIFEST_DIR="$GITHUB_WORKSPACE/OrangeFox"
ORANGEFOX_ROOT="$MANIFEST_DIR/fox_$MANIFEST_BRANCH"
OUTPUT_DIR="$ORANGEFOX_ROOT/out/target/product/$DEVICE_NAME"
echo "OUTPUT_DIR="$ORANGEFOX_ROOT/out/target/product/$DEVICE_NAME"" >> $GITHUB_ENV

mkdir -p "$MANIFEST_DIR"
cd "$MANIFEST_DIR"

# Configure git
git config --global user.name "$GITHUB_ACTOR"
git config --global user.email "$GITHUB_ACTOR_ID+$GITHUB_ACTOR@users.noreply.github.com"

# Clone OrangeFox sync repository
echo "Cloning OrangeFox sync repository..."
git clone https://gitlab.com/OrangeFox/sync.git -b master
cd sync
./orangefox_sync.sh --branch "$MANIFEST_BRANCH" --path "$ORANGEFOX_ROOT"

# Clone device tree
echo "Cloning device tree..."
cd "$ORANGEFOX_ROOT"
git clone "$DEVICE_TREE" -b "$DEVICE_TREE_BRANCH" "./$DEVICE_PATH"

# Build OrangeFox
echo "Building OrangeFox..."
cd "$ORANGEFOX_ROOT"
set +e
export USE_CCACHE=1
export CCACHE_EXEC=/usr/bin/ccache
sed -i 's/return sandboxConfig\.working/return false/g' build/soong/ui/build/sandbox_linux.go
source build/envsetup.sh
export ALLOW_MISSING_DEPENDENCIES=true
set -e
lunch "twrp_$DEVICE_NAME-eng" && make clean && mka adbd "${BUILD_TARGET}image"

# Check if the recovery image exists
img_file=$(find "$OUTPUT_DIR" -name "${BUILD_TARGET}*.img" -print -quit)
zip_file=$(find "$OUTPUT_DIR" -name "OrangeFox*.zip" -print -quit)

if [ -f "$img_file" ]; then
    echo "CHECK_IMG_IS_OK=true" >> $GITHUB_ENV
    set_output "out_img" "$img_file"
    echo "MD5_IMG=$(md5sum "$img_file" | cut -d ' ' -f 1)" >> $GITHUB_ENV
else
    echo "Recovery out directory is empty."
    exit 1
fi

if [ -f "$zip_file" ]; then
    echo "CHECK_ZIP_IS_OK=true" >> $GITHUB_ENV
    set_output "out_zip" "$zip_file"
    echo "MD5_ZIP=$(md5sum "$zip_file" | cut -d ' ' -f 1)" >> $GITHUB_ENV
else
    echo "::warning::The zip file isn't present but make sure the image is from only after 100% completion in build stage"
fi
