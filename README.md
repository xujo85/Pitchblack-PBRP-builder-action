# PBRP Build Action

This GitHub Action allows you to build [PitchBlack Recovery Project (PBRP)](https://pitchblackrecovery.com/) for a specified Android device. It automates the process of setting up the build environment, syncing sources, and compiling the recovery image using your device's tree and the PBRP source code.

This action is flexible and can automatically extract necessary build parameters from your device tree if they are not provided explicitly.

---

## Table of Contents

- [Features](#features)
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

## Features

- **Automatic Environment Setup:** Installs all necessary packages and tools required for building PBRP.
- **Flexible Device Tree Handling:** Clones your device tree and can extract `DEVICE_NAME` and `DEVICE_PATH` from `.mk` files if not provided.
- **Customizable Build Options:** Allows you to specify the build target and whether to use LDCHECK for dependency checking.
- **Branch Handling:** If the device tree branch or manifest branch is not specified, the action will clone the default branch of the repository.

---

## Usage

To use this action in your workflow, add it as a step in your GitHub Actions workflow YAML file. The action can either accept device-specific parameters or attempt to extract them from your device tree's `.mk` files if they are not provided.

---

## Inputs

This action accepts the following inputs:

| Input                | Description                                                                                                                                   | Required | Default               |
|----------------------|-----------------------------------------------------------------------------------------------------------------------------------------------|----------|-----------------------|
| `MANIFEST_BRANCH`    | PBRP Manifest Branch (e.g., 'android-12.1'). If not provided, the default manifest branch will be used.                                       | No       | `''` (empty string)   |
| `DEVICE_TREE`        | Custom Recovery Tree URL (your device tree repository).                                                                                       | No       | `"https://github.com/${{ github.repository }}"` |
| `DEVICE_TREE_BRANCH` | Custom Recovery Tree Branch. If not provided, the default branch of the repository will be used.                                              | No       | `''` (empty string)   |
| `DEVICE_NAME`        | Device Codename (leave blank to auto-detect from the device tree).                                                                            | No       | `''` (empty string)   |
| `DEVICE_PATH`        | Device Path (leave blank to auto-detect; e.g., 'device/manufacturer/codename').                                                               | No       | `''` (empty string)   |
| `BUILD_TARGET`       | Build Target ('pbrp', 'recovery', 'boot', or 'vendorboot'). Use 'pbrp' for Android 11 or above.                                               | No       | `'recovery'`          |

For LDCHECK, You can use this [action](https://github.com/mlm-games/ldcheck-action).

**Notes:**

- If `DEVICE_NAME` and `DEVICE_PATH` are not provided, the action will attempt to extract them from the `.mk` files in your device tree.
- If `DEVICE_TREE_BRANCH` is not provided, the action will clone the default branch of the device tree repository.
- If `MANIFEST_BRANCH` is not provided, the action will initialize the PBRP repo with its default branch.

---

## Outputs

This action sets the following environment variables that can be used in subsequent steps:

- `OUTPUT_DIR`: The directory where the built recovery image and associated files are located.

You can access this variable using `${{ env.OUTPUT_DIR }}` in your workflow.

---

## Example Workflows

### Example with Provided Device Name and Path

```yaml
name: Build PBRP Recovery

on:
  push:
    branches: [ main ]
  workflow_dispatch:

jobs:
  build:
    name: Build PBRP Recovery with Provided Device Info
    runs-on: ubuntu-20.04
    steps:
    - uses: actions/checkout@v4

    - name: Set Swap Space (Optional)
      uses: pierotofy/set-swap-space@master
      with:
        swap-size-gb: 16

    - name: Build PBRP
      uses: mlm-games/pbrp-build-action@main
      with:
        MANIFEST_BRANCH: 'android-12.1'
        DEVICE_TREE: 'https://github.com/your-username/device_manufacturer_codename'
        DEVICE_TREE_BRANCH: 'main'
        DEVICE_NAME: 'your_device_codename'
        DEVICE_PATH: 'device/manufacturer/codename'
        BUILD_TARGET: 'pbrp'   # Use 'pbrp' for Android 11 or above

    - name: Upload Recovery Image
      uses: actions/upload-artifact@v3
      with:
        name: PBRP-Recovery
        path: ${{ env.OUTPUT_DIR }}/*.img
```

### Example with Auto-Detection of Device Name and Path

```yaml
name: Build PBRP Recovery

on:
  push:
    branches: [ main ]
  workflow_dispatch:

jobs:
  build:
    name: Build PBRP Recovery with Auto-Detection
    runs-on: ubuntu-20.04
    steps:
    - uses: actions/checkout@v4

    - name: Set Swap Space (Optional)
      uses: pierotofy/set-swap-space@master
      with:
        swap-size-gb: 16

    - name: Build PBRP
      uses: mlm-games/pbrp-build-action@main
      with:
        # MANIFEST_BRANCH is omitted to use the default branch
        DEVICE_TREE: 'https://github.com/your-username/device_manufacturer_codename'
        # DEVICE_TREE_BRANCH is omitted to use the default branch
        BUILD_TARGET: 'pbrp'       # Use 'pbrp' for Android 11 or above
        # DEVICE_NAME and DEVICE_PATH are omitted to auto-detect

    - name: Upload Recovery Image
      uses: actions/upload-artifact@v3
      with:
        name: PBRP-Recovery
        path: ${{ env.OUTPUT_DIR }}/*.img
```

In this example:

- `DEVICE_NAME` and `DEVICE_PATH` are omitted. The action will attempt to extract these values from the `.mk` files in your device tree.
- `DEVICE_TREE_BRANCH` is omitted, so the default branch of the device tree repository will be used.
- `MANIFEST_BRANCH` is omitted, so the action will initialize the PBRP repo with its default branch.

---

## Notes

- **Device Tree Requirements:** Ensure your device tree is properly configured for PBRP. The action relies on variables like `PRODUCT_NAME`, `PRODUCT_BRAND`, and `PRODUCT_DEVICE` being correctly set in your `.mk` files.
- **Build Time:** The build process can take a significant amount of time depending on the device and available system resources.
- **Storage Space:** Make sure you have sufficient storage space available. Consider using actions like `actions/upload-artifact` to store build artifacts.
- **Environment Variables:** The `OUTPUT_DIR` environment variable is set to the output directory of the build. You can access it in subsequent steps to retrieve built files.
- **Swap Space:** For devices with large build requirements, incorporating swap space can improve build success and performance. Use the [pierotofy/set-swap-space](https://github.com/pierotofy/set-swap-space) action to add swap space to your runner.
- **Legacy Branches:** If you are building for a legacy branch (older than Android 11), the action will install Python 2 as it may be required for the build process.

---

## Support

If you encounter any issues, have questions, or need assistance, please open an issue in the [GitHub repository](https://github.com/your-username/pbrp-build-action/issues).

---

## License

This project is licensed under the [MIT License](LICENSE).

---

## Additional Information

### Environment Variable `OUTPUT_DIR`

The action sets an environment variable `OUTPUT_DIR` which points to the directory containing the built PBRP recovery image and related files. You can use this variable in subsequent steps to access the build artifacts.

```bash
echo "OUTPUT_DIR=$MANIFEST_DIR/out/target/product/$DEVICE_NAME" >> $GITHUB_ENV
```

Access it in your workflow using `${{ env.OUTPUT_DIR }}`.

### Uploading Artifacts

After building, you may want to upload the recovery image or ZIP file as an artifact:

```yaml
- name: Upload Recovery Image
  uses: actions/upload-artifact@v3
  with:
    name: PBRP-Recovery
    path: ${{ env.OUTPUT_DIR }}/*.img

- name: Upload Recovery ZIP
  if: success() && env.CHECK_ZIP_IS_OK == 'true'
  uses: actions/upload-artifact@v3
  with:
    name: PBRP-Recovery-ZIP
    path: ${{ env.OUTPUT_DIR }}/*.zip
```

### Incorporating LDCHECK

The other action will run LDCHECK after the build in the same output directory to check for missing dependencies in the recovery's blobs. You need to specify the `LDCHECKPATH` for the blobs you want to check.

### Advanced Usage

#### Incorporating Swap Space

For devices with large build requirements, incorporating swap space can improve build success and performance.

```yaml
- name: Set Swap Space
  uses: pierotofy/set-swap-space@master
  with:
    swap-size-gb: 24
```

Make sure to adjust the swap size according to your needs.

---

## Troubleshooting

- **Failed to Extract Device Information:** If the action fails to extract `DEVICE_NAME` or `DEVICE_PATH`, ensure that your `.mk` files contain the necessary variables (`PRODUCT_NAME`, `PRODUCT_BRAND`, `PRODUCT_DEVICE`).
- **Build Failures:** Check the build logs for error messages. Common issues include missing dependencies or misconfigured device trees.
- **Insufficient Resources:** GitHub Actions runners have limitations on CPU and memory. For resource-intensive builds, consider using self-hosted runners or optimizing your device tree.
- **Branch Compatibility:** Ensure that the `MANIFEST_BRANCH` and `DEVICE_TREE_BRANCH` are compatible with each other. Using mismatched branches may result in build errors.

---

## Contributing

Contributions, issues, and feature requests are welcome! Feel free to check [issues page](https://github.com/mlm-games/pbrp-build-action/issues) if you want to contribute.

---

## Acknowledgements

- [PitchBlack Recovery Project](https://pitchblackrecovery.com/)
- [GitHub Actions](https://github.com/features/actions)

---

## Disclaimer

This action is provided as-is without any warranty. Use it at your own risk. The maintainers are not responsible for any damages or issues arising from its use.

Feel free to customize and extend this action to suit your specific needs. Contributions and improvements are welcome!
