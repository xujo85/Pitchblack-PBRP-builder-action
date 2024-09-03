# orangefox-builder-action

This GitHub Action allows you to build OrangeFox recovery for a specified device.

Use it with other actions for cleanup, swap space (and ccache for v1.1) 

## Usage

To use this action in your workflow, create a `.yml` file in your `.github/workflows` directory with the following content:

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
    runs-on: ubuntu-latest
    steps:
    - uses: actions/checkout@v4
    - name: Build OrangeFox
      uses: mlm-games/OrangeFox-Build-Action@main
      with:
        MANIFEST_BRANCH: '12.1'
        DEVICE_TREE: 'https://github.com/ur-github-username/device_manufacturer_codename'
        DEVICE_TREE_BRANCH: 'android-12.1'
        DEVICE_NAME: 'your_device_codename'
        DEVICE_PATH: 'device/manufacturer/codename'
        BUILD_TARGET: 'recovery'
```

## Inputs

This action accepts the following inputs:

| Input | Description | Required | Default |
|-------|-------------|----------|---------|
| `MANIFEST_BRANCH` | OrangeFox Manifest Branch | Yes | '12.1' |
| `DEVICE_TREE` | Custom Recovery Tree URL | Yes | - |
| `DEVICE_TREE_BRANCH` | Custom Recovery Tree Branch | Yes | - |
| `DEVICE_NAME` | Device Codename | Yes | - |
| `DEVICE_PATH` | Device Path | Yes | - |
| `BUILD_TARGET` | Build Target | Yes | 'recovery' |

## Outputs

This action will create a release with the built OrangeFox recovery image and related files.

## Example

Here's an example of how to use this action in a workflow:

```yaml
name: Build OrangeFox Recovery

on:
  push:
    branches: [ main ]
  workflow_dispatch:

jobs:
  build:
    runs-on: ubuntu-latest
    steps:
    - uses: actions/checkout@v4
    - name: Build OrangeFox
      uses: mlm-games/OrangeFox-Build-Action@main
      with:
        MANIFEST_BRANCH: '12.1'
        DEVICE_TREE: 'https://github.com/mlm-games/device_samsung_a51'
        DEVICE_TREE_BRANCH: 'android-12.1'
        DEVICE_NAME: 'a51'
        DEVICE_PATH: 'device/samsung/a51'
        BUILD_TARGET: 'recovery'
```

This example builds OrangeFox recovery for a Samsung A51 device.

## Notes

- Ensure your device tree is properly configured for OrangeFox recovery.
- The build process can take a significant amount of time depending on the device and system resources.
- Make sure you have sufficient storage space in your GitHub repository for the build artifacts.

## Support

If you encounter any issues or have questions, please open an issue in the GitHub repository.

## License

This project is licensed under the [GPL 3.0 License](LICENSE).
