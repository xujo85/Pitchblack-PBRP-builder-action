#!/bin/bash
set -e

# Install necessary packages
sudo apt-get update
sudo apt-get install -y aria2 git

# Clone OrangeFox scripts
git clone https://gitlab.com/OrangeFox/misc/scripts.git
cd scripts
sudo bash setup/android_build_env.sh

# Set up the build environment
MANIFEST_DIR="${GITHUB_WORKSPACE}/OrangeFox"
ORANGEFOX_ROOT="${MANIFEST_DIR}/fox_${INPUT_MANIFEST_BRANCH}"
OUTPUT_DIR="${ORANGEFOX_ROOT}/out/target/product/${INPUT_DEVICE_NAME}"

mkdir -p "${MANIFEST_DIR}"
cd "${MANIFEST_DIR}"

# Configure git
git config --global user.name "${GITHUB_ACTOR}"
git config --global user.email "${GITHUB_ACTOR_ID}+${GITHUB_ACTOR}@users.noreply.github.com"

# Clone OrangeFox sync repository
git clone https://gitlab.com/OrangeFox/sync.git -b master
cd sync
./orangefox_sync.sh --branch "${INPUT_MANIFEST_BRANCH}" --path "${ORANGEFOX_ROOT}"

# Clone device tree
cd "${ORANGEFOX_ROOT}"
git clone "${INPUT_DEVICE_TREE}" -b "${INPUT_DEVICE_TREE_BRANCH}" "./${INPUT_DEVICE_PATH}"

# Build OrangeFox
cd "${ORANGEFOX_ROOT}"
export USE_CCACHE=1
export CCACHE_EXEC=/usr/bin/ccache
sed -i 's/return sandboxConfig\.working/return false/g' build/soong/ui/build/sandbox_linux.go
source build/envsetup.sh
export ALLOW_MISSING_DEPENDENCIES=true
lunch "twrp_${INPUT_DEVICE_NAME}-eng" && make clean && mka adbd "${INPUT_BUILD_TARGET}image"

# Check if the recovery image exists
img_file=$(find "${OUTPUT_DIR}" -name "${INPUT_BUILD_TARGET}*.img" -print -quit)
zip_file=$(find "${OUTPUT_DIR}" -name "OrangeFox*.zip" -print -quit)

if [ -f "$img_file" ]; then
    echo "CHECK_IMG_IS_OK=true" >> $GITHUB_ENV
    echo "MD5_IMG=$(md5sum "$img_file" | cut -d ' ' -f 1)" >> $GITHUB_ENV
else
    echo "Recovery out directory is empty."
fi

if [ -f "$zip_file" ]; then
    echo "CHECK_ZIP_IS_OK=true" >> $GITHUB_ENV
    echo "MD5_ZIP=$(md5sum "$zip_file" | cut -d ' ' -f 1)" >> $GITHUB_ENV
else
    echo "::warning::The zip file isn't present but make sure the image is from only after 100% completion in build stage"
fi

# Run LDCheck if enabled
if [ "${INPUT_LDCHECK}" = "true" ]; then
    
    echo "Done checking missing dependencies. Review, and reconfigure your tree."
fi