# OrangeFox Build Action

This GitHub Action allows you to build OrangeFox Recovery for a specified Android device. It automates the process of building the recovery image using your device's tree and the OrangeFox source code.

This action is flexible and can automatically extract necessary build parameters from your device tree if they are not provided explicitly.

---

## Table of Contents

- [Usage](#usage)
- [Inputs](#inputs)
- [Outputs](#outputs)
- [Example Workflows](#example-workflows)
  - [Example with Provided Device Name and Path](#example-with-provided-device-name-and-path)
  - [Example with Auto-Detection of Device Name and Path](#example-with-auto-detection-of-device-name-and-path)
- [Notes](#notes)
- [Support](#support)
- [License](#license)

---

## Usage

To use this action in your workflow, add it as a step in your GitHub Actions workflow YAML file. The action can either accept device-specific parameters or attempt to extract them from your device tree's `.mk` files if they are not provided.

---

## Inputs

This action accepts the following inputs:

| Input                | Description                                                                                                             | Required | Default               |
|----------------------|-------------------------------------------------------------------------------------------------------------------------|----------|-----------------------|
| `MANIFEST_BRANCH`    | OrangeFox Manifest Branch (e.g., '12.1' or '11.0')                                                                      | No       | `'12.1'`              |
| `DEVICE_TREE`        | Custom Recovery Tree URL                                                                                                | No       | `"https://github.com/${{ github.repository }}"` |
| `DEVICE_TREE_BRANCH` | Custom Recovery Tree Branch                                                                                             | No       | `'main'`              |
| `DEVICE_NAME`        | Device Codename (leave blank to auto-detect from the device tree)                                                       | No       | `''` (empty string)   |
| `DEVICE_PATH`        | Device Path (leave blank to auto-detect; e.g., 'device/manufacturer/codename')                                          | No       | `''` (empty string)   |
| `BUILD_TARGET`       | Build Target ('recovery', 'boot', or 'vendorboot')                                                                      | No       | `'recovery'`          |

**Notes:**

- If `DEVICE_NAME` and `DEVICE_PATH` are not provided, the action will attempt to extract them from the `.mk` files in your device tree.
- The default `DEVICE_TREE` URL is set to your repository. If your device tree is in a different repository, you should provide the correct URL.

---

## Outputs

This action sets the following environment variables that can be used in subsequent steps:

- `OUTPUT_DIR`: The directory where the built recovery image and associated files are located.

You can access this variable using `${{ env.OUTPUT_DIR }}` in your workflow.

---

## Example Workflows

### Example with Provided Device Name and Path

```yaml
name: Build OrangeFox Recovery

on:
  push:
    branches: [ main ]
  pull_request:
    branches: [ main ]
  workflow_dispatch:

jobs:
  build:
    name: Build OrangeFox Recovery with Provided Device Info
    runs-on: ubuntu-latest
    steps:
    - uses: actions/checkout@v4
    - name: Build OrangeFox
      uses: your-username/orangefox-builder-action@main
      with:
        MANIFEST_BRANCH: '12.1'
        DEVICE_TREE: 'https://github.com/your-username/device_manufacturer_codename'
        DEVICE_TREE_BRANCH: 'android-12.1'
        DEVICE_NAME: 'your_device_codename'
        DEVICE_PATH: 'device/manufacturer/codename'
        BUILD_TARGET: 'recovery'
    - name: Upload Recovery Image
      uses: actions/upload-artifact@v3
      with:
        name: OrangeFox-Recovery
        path: ${{ env.OUTPUT_DIR }}/*.img
```

### Example with Auto-Detection of Device Name and Path

```yaml
name: Build OrangeFox Recovery

on:
  push:
    branches: [ main ]
  pull_request:
    branches: [ main ]
  workflow_dispatch:

jobs:
  build:
    name: Build OrangeFox Recovery with Auto-Detection
    runs-on: ubuntu-latest
    steps:
    - uses: actions/checkout@v4
    - name: Build OrangeFox
      uses: your-username/orangefox-builder-action@main
      with:
        MANIFEST_BRANCH: '12.1'
        DEVICE_TREE: 'https://github.com/your-username/device_manufacturer_codename'
        DEVICE_TREE_BRANCH: 'android-12.1'
        BUILD_TARGET: 'recovery'  # DEVICE_NAME and DEVICE_PATH are omitted
    - name: Upload Recovery Image
      uses: actions/upload-artifact@v3
      with:
        name: OrangeFox-Recovery
        path: ${{ env.OUTPUT_DIR }}/*.img
```

In this example, `DEVICE_NAME` and `DEVICE_PATH` are omitted. The action will attempt to extract these values from the `.mk` files in your device tree.

(Also you can omit everything else too, it will just build a 12.1 recovery image for your repo's main branch.) 

---

## Notes

- **Device Tree Requirements:** Ensure your device tree is properly configured for OrangeFox Recovery. The action relies on variables like `PRODUCT_NAME`, `PRODUCT_BRAND`, and `PRODUCT_DEVICE` being correctly set in your `.mk` files.
- **Build Time:** The build process can take a significant amount of time depending on the device and available system resources.
- **Storage Space:** Make sure you have sufficient storage space available. Consider using actions like `actions/upload-artifact` to store build artifacts.
- **Environment Variables:** The `OUTPUT_DIR` environment variable is set to the output directory of the build. You can access it in subsequent steps to retrieve built files.

---

## Support

If you encounter any issues, have questions, or need assistance, please open an issue in the [GitHub repository](https://github.com/your-username/orangefox-builder-action/issues).

---

## License

This project is licensed under the [GPL-3.0 License](LICENSE).

---

## Additional Information

### Environment Variable `OUTPUT_DIR`

The action sets an environment variable `OUTPUT_DIR` which points to the directory containing the built OrangeFox Recovery image and related files. You can use this variable in subsequent steps to access the build artifacts.

```yaml
echo "OUTPUT_DIR=$ORANGEFOX_ROOT/out/target/product/$DEVICE_NAME" >> $GITHUB_ENV
```

Access it in your workflow using `${{ env.OUTPUT_DIR }}`.

### Uploading Artifacts

After building, you may want to upload the recovery image or ZIP file as an artifact:

```yaml
- name: Upload Recovery Image
  uses: actions/upload-artifact@v3
  with:
    name: OrangeFox-Recovery
    path: ${{ env.OUTPUT_DIR }}/*.img

- name: Upload Recovery ZIP
  if: success() && env.CHECK_ZIP_IS_OK == 'true'
  uses: actions/upload-artifact@v3
  with:
    name: OrangeFox-Recovery-ZIP
    path: ${{ env.OUTPUT_DIR }}/*.zip
```

---

## Advanced Usage

### Incorporating Swap Space and CCache

For devices with large build requirements, incorporating swap space or ccache can improve build success and performance.

```yaml
- name: Set up Swap Space
  run: |
    sudo fallocate -l 8G /swapfile
    sudo chmod 600 /swapfile
    sudo mkswap /swapfile
    sudo swapon /swapfile
    sudo swapon --show

- name: Set up CCache
  run: |
    sudo apt-get install -y ccache
    echo "export USE_CCACHE=1" >> $GITHUB_ENV
    echo "export CCACHE_DIR=/tmp/ccache" >> $GITHUB_ENV
    ccache -M 20G
```

Make sure to adjust swap size and ccache size according to your needs.

---

## Troubleshooting

- **Failed to Extract Device Information:** If the action fails to extract `DEVICE_NAME` or `DEVICE_PATH`, ensure that your `.mk` files contain the necessary variables (`PRODUCT_NAME`, `PRODUCT_BRAND`, `PRODUCT_DEVICE`).
- **Build Failures:** Check the build logs for error messages. Common issues include missing dependencies or misconfigured device trees.
- **Insufficient Resources:** GitHub Actions runners have limitations on CPU and memory. For resource-intensive builds, consider using self-hosted runners or optimizing your device tree.

---

Feel free to customize and extend this action to suit your specific needs. Contributions and improvements are welcome!
