# BridgeX

BridgeX is an experimental jailbreak tweak project exploring a CarBridge-style experience on supported rootless iOS devices.

**Current stage: foundation scaffold only.** CarPlay app injection, video playback, touch forwarding, game support, per-app configuration, orientation handling, and all other CarPlay features are **not implemented**. No CarPlay integration should be considered working until built and tested on-device.

## Intended test target

- Device: iPhone 8 (ARM64)
- iOS: 15.1
- Jailbreak: Dopamine 3.0.13
- Build system: Theos
- Package scheme: rootless
- Package identifier: `com.tego.bridgex`
- Initial version: `0.1.0`

The Makefile sets an iOS 15.0 minimum deployment target; the intended device runs iOS 15.1.

## Project layout

```text
.
├── Makefile
├── control
├── Tweak.m
├── BridgeX.plist
├── LICENSE
├── README.md
├── .gitignore
├── Preferences/
│   ├── Makefile
│   ├── BridgeXPrefs.plist
│   └── BridgeXRootListController.m
└── layout/
    └── Library/PreferenceLoader/Preferences/BridgeX.plist
```

The Theos tweak target uses the root-level `BridgeX.plist` as its injection filter. The preferences bundle is a placeholder pane registered through the PreferenceLoader layout file.

## Build environment

Build on macOS with:

1. Xcode Command Line Tools installed.
2. Theos installed and `THEOS` pointing to its installation directory.
3. An iOS SDK supported by the installed Theos toolchain.
4. An iPhoneOS ARM64 compiler/linker toolchain.
5. Debian packaging tools and `ldid` available to Theos.

A typical Theos checkout and shell setup:

```sh
git clone --recursive https://github.com/theos/theos.git "$HOME/theos"
echo 'export THEOS="$HOME/theos"' >> ~/.zshrc
source ~/.zshrc
```

If Theos is already installed, do not clone it again; set `THEOS` to the existing installation path. Install any additional dependencies required by your Theos version using the official documentation: https://theos.dev/docs/

## Build

From the repository root:

```sh
make clean
make package
```

The package should appear under `packages/`. The package metadata declares `iphoneos-arm`; `THEOS_PACKAGE_SCHEME := rootless` configures Theos' rootless packaging behavior.

A successful package build does not establish that injection, preferences, or runtime behavior work on-device.

## Install and verify

You can transfer the resulting package to the jailbroken iPhone and install it with a rootless-compatible package manager such as Sileo. Confirm that the package is recognized as rootless before installation.

For SSH deployment, configure device SSH access and then run:

```sh
THEOS_DEVICE_IP=<device-ip> THEOS_DEVICE_PORT=22 make install
```

Replace the placeholder with the device's reachable address. Do not run this until SSH access is configured. After installation, check package-manager installation, inspect device logs for the `[BridgeX]` load message, and confirm SpringBoard remains stable. Remove the package if it causes instability.

## Implementation status

| Component | Status |
|---|---|
| Rootless Theos Makefile | Added; build not verified |
| ARM64 target | Configured; compiler output not verified |
| Debian package metadata | Added; package not built |
| Tweak entry point | Minimal constructor log only; not device-tested |
| SpringBoard filter | Added; injection not verified |
| Preferences bundle | Placeholder controller; not compiled |
| PreferenceLoader registration | Added; not verified |
| CarPlay integration | **Not implemented or tested** |

## Next milestones

1. Build the package with the target Theos environment and resolve compiler/packaging errors.
2. Inspect the generated Debian package contents and rootless paths.
3. Install on the iPhone 8 running iOS 15.1 with Dopamine 3.0.13.
4. Verify library loading, SpringBoard stability, and preferences loading.
5. Only then begin implementing and testing actual CarPlay-related functionality.

## License

BridgeX is licensed under the GNU General Public License, version 3 or (at your option) any later version. See [LICENSE](LICENSE). New source files should carry the SPDX identifier `GPL-3.0-or-later`.
