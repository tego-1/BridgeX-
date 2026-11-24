# BridgeX

BridgeX is an experimental rootless iOS tweak project exploring a CarBridge-style experience on supported rootless iOS devices.

**Current stage: verified injection foundation only.** CarPlay app injection, video playback, touch forwarding, game support, per-app configuration, orientation handling, and all other CarPlay features are **not implemented**. A successful injection test does not mean CarPlay functionality works.

## Intended and verified test target

- Device: iPhone 8 (ARM64)
- iOS: 15.1
- Jailbreak: Dopamine 3.0.13
- Build system: Theos
- Package scheme: rootless
- Package identifier: `com.tego.bridgex`
- Tested package version: `0.1.0-4+debug`

The Makefile sets an iOS 15.0 minimum deployment target; the test device runs iOS 15.1.

## Project layout

```text
.
├── Makefile
├── control
├── Tweak.m
├── BridgeX.plist
├── LICENSE
├── README.md
└── Preferences/       # experimental sources; not currently registered as a Settings pane
```

The root-level `BridgeX.plist` is the tweak's injection filter. The separate PreferenceLoader registration was removed while isolating a Settings-related issue; do not assume a BridgeX Settings pane is currently available.

## Build environment

Build on macOS with:

1. Xcode Command Line Tools installed.
2. Theos installed and `THEOS` pointing to its installation directory.
3. An iOS SDK supported by the installed Theos toolchain.
4. An iPhoneOS ARM64 compiler/linker toolchain.
5. Debian packaging tools and `ldid` available to Theos.

If Theos is already installed, do not clone it again; set `THEOS` to the existing installation path. Install any additional dependencies required by your Theos version using the official documentation: https://theos.dev/docs/

## Build

From the repository root:

```sh
make clean
make package
```

The package is generated under `packages/`. A successful package build confirms compilation and packaging, but does not by itself establish that the tweak loads or behaves correctly on-device.

## Install and verify

Transfer the generated package to the jailbroken iPhone and install it with a rootless-compatible package manager. After installation, verify the package status, dynamic library and filter files, and device logs. Remove the package if it causes instability.

For SSH deployment, configure device SSH access and then run:

```sh
THEOS_DEVICE_IP=<device-ip> THEOS_DEVICE_PORT=22 make install
```

Replace the placeholder with the device's reachable address. Do not run this until SSH access is configured.

## Verified baseline — 2026-11-23

The following was completed on the intended iPhone 8 / iOS 15.1 / Dopamine test device:

- Theos successfully compiled the ARM64 tweak and generated a Debian package.
- Package manager reported `com.tego.bridgex` installed, version `0.1.0-4+debug`, architecture `iphoneos-arm64`.
- `/var/jb/Library/MobileSubstrate/DynamicLibraries/BridgeX.dylib` and `BridgeX.plist` were present on-device.
- After installation and respring, the device remained usable with no obvious crash or freeze.
- Xcode's connected-device console displayed the exact constructor message:
  `[BridgeX] Foundation loaded (no CarPlay integration implemented).`

This confirms that the dynamic library was loaded and its constructor executed in the configured injection target. It does **not** verify any CarPlay behavior, preferences UI, or broader runtime correctness.

## Implementation status

| Component | Status |
|---|---|
| Rootless Theos build | Built successfully |
| ARM64 package | Generated successfully |
| Package installation | Verified on target device |
| Dynamic library and injection filter files | Present on target device |
| Constructor execution | Confirmed in Xcode device console |
| Post-respring stability | No obvious crash or freeze observed |
| Preferences pane | Not currently registered; experimental sources only |
| CarPlay integration | **Not implemented or tested** |

## Next milestones

1. Preserve this verified injection baseline.
2. Improve initialization diagnostics and safe error handling.
3. Organize the tweak into maintainable modules before adding larger features.
4. Research the relevant iOS 15 CarPlay architecture and constraints.
5. Implement and test CarPlay-related functionality incrementally on-device.

## License

BridgeX is licensed under the GNU General Public License, version 3 or (at your option) any later version. See [LICENSE](LICENSE). New source files should carry the SPDX identifier `GPL-3.0-or-later`.
