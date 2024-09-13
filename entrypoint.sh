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
mkdir -p "$MANIFEST_DIR"
cd "$MANIFEST_DIR"

# Configure git
git config --global user.name "$GITHUB_ACTOR"
git config --global user.email "$GITHUB_ACTOR_ID+$GITHUB_ACTOR@users.noreply.github.com"

# Clone OrangeFox sync repository
echo "Cloning OrangeFox sync repository..."
git clone https://gitlab.com/OrangeFox/sync.git -b master
cd sync
./orangefox_sync.sh --branch "$MANIFEST_BRANCH" --path "$MANIFEST_DIR/fox_$MANIFEST_BRANCH"

# Clone device tree into a temporary directory
echo "Cloning device tree..."
cd "$MANIFEST_DIR/fox_$MANIFEST_BRANCH"
git clone "$DEVICE_TREE" -b "$DEVICE_TREE_BRANCH" tmp_device_tree

# Check if DEVICE_NAME or DEVICE_PATH are default or not provided
if [ -z "$DEVICE_NAME" ] || [ "$DEVICE_NAME" == "codename" ] || [ -z "$DEVICE_PATH" ] || [ "$DEVICE_PATH" == "device/company/codename" ]; then
    echo "Extracting variables from .mk files..."
    cd tmp_device_tree

    # Initialize variables
    DEVICE_MAKEFILE=""
    DEVICE_DIRECTORY=""
    DEVICE_NAME=""
    BRAND=""
    
    # Search for .mk files recursively in the device tree
    mk_files=$(find . -type f -name '*.mk')
    
    # Loop through each .mk file found
    for file in $mk_files; do
        # Extract variables using sed
        makefile=$(sed -n 's/^[[:space:]]*PRODUCT_NAME[[:space:]]*:=\s*\(.*\)/\1/p' "$file")
        brand=$(sed -n 's/^[[:space:]]*PRODUCT_BRAND[[:space:]]*:=\s*\(.*\)/\1/p' "$file")
        codename=$(sed -n 's/^[[:space:]]*PRODUCT_DEVICE[[:space:]]*:=\s*\(.*\)/\1/p' "$file")
        if [[ -n "$makefile" && -n "$brand" && -n "$codename" ]]; then
            DEVICE_MAKEFILE="$makefile"
            BRAND="$brand"
            DEVICE_NAME="$codename"
            DEVICE_PATH="device/$brand/$codename"
            echo "DEVICE_MAKEFILE=${DEVICE_MAKEFILE}" >> $GITHUB_ENV
            echo "DEVICE_NAME=${DEVICE_NAME}" >> $GITHUB_ENV
            echo "BRAND=${BRAND}" >> $GITHUB_ENV
            echo "DEVICE_PATH=${DEVICE_PATH}" >> $GITHUB_ENV
            break
        fi
    done

    # Verify that DEVICE_NAME was found
    if [ -z "$DEVICE_NAME" ]; then
        echo "::error::Failed to extract DEVICE_NAME from .mk files."
        exit 1
    fi

    # Navigate back to the root
    cd "$MANIFEST_DIR/fox_$MANIFEST_BRANCH"

    # Move the device tree into the correct directory
    echo "Moving device tree to $DEVICE_PATH"
    mkdir -p "$DEVICE_PATH"
    mv tmp_device_tree/* "$DEVICE_PATH/"
    rm -rf tmp_device_tree
else
    echo "Using provided DEVICE_NAME and DEVICE_PATH"
    # Move device tree to the specified DEVICE_PATH
    mkdir -p "$DEVICE_PATH"
    mv tmp_device_tree/* "$DEVICE_PATH/"
    rm -rf tmp_device_tree
fi

# Set ORANGEFOX_ROOT and OUTPUT_DIR now that DEVICE_NAME is known
ORANGEFOX_ROOT="$MANIFEST_DIR/fox_$MANIFEST_BRANCH"
echo "ORANGEFOX_ROOT=${ORANGEFOX_ROOT}" >> $GITHUB_ENV
OUTPUT_DIR="$ORANGEFOX_ROOT/out/target/product/$DEVICE_NAME"
echo "OUTPUT_DIR=${OUTPUT_DIR}" >> $GITHUB_ENV

# Build OrangeFox
echo "Building OrangeFox..."
cd "$ORANGEFOX_ROOT"
set +e
sed -i 's/return sandboxConfig\.working/return false/g' build/soong/ui/build/sandbox_linux.go || true
source build/envsetup.sh
export ALLOW_MISSING_DEPENDENCIES=true
set -e
lunch "twrp_${DEVICE_NAME}-eng"
make clean
mka -j$(nproc) adbd "${BUILD_TARGET}image"

# Check if the recovery image exists
img_file=$(find "$OUTPUT_DIR" -name "${BUILD_TARGET}*.img" -print -quit)
zip_file=$(find "$OUTPUT_DIR" -name "OrangeFox*.zip" -print -quit)

if [ -f "$img_file" ]; then
    echo "CHECK_IMG_IS_OK=true" >> $GITHUB_ENV
    set_output "out_img" "$img_file"
    echo "MD5_IMG=$(md5sum "$img_file" | cut -d ' ' -f 1)" >> $GITHUB_ENV
else
    echo "::error::Recovery image not found."
    exit 1
fi

if [ -f "$zip_file" ]; then
    echo "CHECK_ZIP_IS_OK=true" >> $GITHUB_ENV
    set_output "out_zip" "$zip_file"
    echo "MD5_ZIP=$(md5sum "$zip_file" | cut -d ' ' -f 1)" >> $GITHUB_ENV
else
    echo "::warning::The zip file isn't present. Ensure the build completed successfully."
fi
