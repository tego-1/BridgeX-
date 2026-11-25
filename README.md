# BridgeX

BridgeX is an experimental rootless iOS tweak project exploring a CarBridge-style experience on supported rootless iOS devices.

**Current stage: verified tweak injection, companion-app IPC, shared preference storage, and opt-in startup diagnostics.** CarPlay app injection, video playback, touch forwarding, game support, per-app configuration, orientation handling, and all other CarPlay features are **not implemented**. A successful injection test does not mean CarPlay functionality works.

## Intended and verified test target

- Device: iPhone 8 (ARM64)
- iOS: 15.1
- Jailbreak: Dopamine 3.0.13
- Build system: Theos
- Package scheme: rootless
- Package identifier: `com.tego.bridgex`
- App bundle: `com.tego.bridgex`

The Makefile sets an iOS 15.0 minimum deployment target; the test device runs iOS 15.1.

## Project layout

```text
.
├── Makefile
├── control
├── Tweak.m
├── BridgeX.plist
├── BridgeXDiagnostics.h/.m
├── BridgeXIPC.h/.m
├── BridgeXSettingsIPC.h/.m
├── Preferences/
│   ├── Makefile
│   ├── BridgeXRootListController.m
│   ├── Info.plist
│   └── Root.plist
├── layout/
│   └── Library/PreferenceLoader/Preferences/BridgeXPrefs.plist
├── BridgeXApp/
└── README.md
```

The root-level `BridgeX.plist` is the tweak's injection filter. The native Settings pane is built as a Theos subproject and registered through PreferenceLoader. Its `Verbose Diagnostics` switch writes the same `com.tego.bridgex` / `VerboseDiagnosticsEnabled` preference used by the companion app's SpringBoard-mediated settings IPC.

**Verbose Diagnostics behavior:** when enabled, the tweak reads the shared preference during SpringBoard startup and writes a runtime report to the SpringBoard log. A missing or invalid preference is treated as disabled. Changes to the switch take effect on the next SpringBoard launch. The separate one-line foundation startup message remains unconditional.

## Build environment

Build on macOS with:

1. Xcode Command Line Tools installed.
2. Theos installed and `THEOS` pointing to its installation directory.
3. An iOS SDK supported by the installed Theos toolchain.
4. An iPhoneOS ARM64 compiler/linker toolchain.
5. Debian packaging tools and `ldid` available to Theos.

If Theos is already installed, do not clone it again; set `THEOS` to the existing installation path. Install any additional dependencies required by your Theos version using the official documentation: https://theos.dev/docs/

The package declares a dependency on PreferenceLoader so the pane can appear in Settings.

## Build

From the repository root:

```sh
make clean
make package
```

The package is generated under `packages/`. A successful package build confirms compilation and packaging, but does not by itself establish that the tweak loads or behaves correctly on-device.

## Install and verify

Transfer the generated package to the jailbroken iPhone and install it with a rootless-compatible package manager. After installation, verify that BridgeX appears in Settings, open its preference pane, and change the Verbose Diagnostics switch. Then verify that the companion app reads the same saved value after reopening.

Do not install a package until its contents have been inspected and the build succeeds. If it causes instability, remove the package with the package manager.

For SSH deployment, configure device SSH access and then run:

```sh
THEOS_DEVICE_IP=<device-ip> THEOS_DEVICE_PORT=22 make install
```

Replace the placeholder with the device's reachable address. Do not run this until SSH access is configured.

## Verified milestones

### Injection foundation

The following was completed on the intended iPhone 8 / iOS 15.1 / Dopamine test device:

- Theos successfully compiled the ARM64 tweak and generated a Debian package.
- The package manager reported `com.tego.bridgex` installed.
- `/var/jb/Library/MobileSubstrate/DynamicLibraries/BridgeX.dylib` and `BridgeX.plist` were present on-device.
- After installation and respring, the device remained usable with no obvious crash or freeze.
- Xcode's connected-device console displayed the constructor message: `[BridgeX] Foundation loaded (no CarPlay integration implemented).`

This confirms that the dynamic library was loaded and its constructor executed in the configured injection target. It does **not** verify CarPlay behavior.

### Companion app status IPC

- SpringBoard's tweak-side Darwin notification listener starts successfully.
- The companion app can send a status request and receive the matching nonce response.
- The app displayed a connected status on the iPhone 8.

This confirms the status IPC round trip, not CarPlay integration.

### Shared preference storage and live synchronization

- The companion app can save the Verbose Diagnostics preference through SpringBoard.
- The native Settings pane and companion app use the same `com.tego.bridgex` preference domain and `VerboseDiagnosticsEnabled` key.
- Save/read-back and bidirectional preference persistence have been verified on an iPhone 8 running iOS 15.1.
- Live synchronization uses a dedicated Darwin notification after a successful preference write.
- The companion app listens for changes and reads the latest value through SpringBoard IPC.
- The native Settings pane listens for changes and reloads its switch.
- The companion app refreshes the preference when returning to the foreground, because iOS may suspend background apps.

The live notification implementation has been built with Theos and Xcode and verified on-device in both directions: native Settings changes update the companion app, and companion-app changes update the native Settings pane without force-closing/reopening either interface.

## Implementation status

| Component | Status |
|---|---|
| Rootless Theos tweak build | Built successfully |
| ARM64 package and injection | Verified on target device |
| Startup diagnostics | Verified in device console |
| SpringBoard ↔ companion app status IPC | Verified |
| Shared preference storage via companion app | Save and app-relaunch read-back verified |
| Native Settings preference pane | Appears in Settings; shared preference read/write verified on device |
| Live two-way preference UI updates | Built and verified in both directions on iPhone 8 / iOS 15.1 |
| Opt-in startup runtime report controlled by preference | Implemented in `feature/verbose-diagnostics`; awaiting local build and device verification |
| CarPlay integration | **Not implemented or tested** |

## Next milestones

1. Build and verify preference-controlled startup diagnostics on the target iPhone.
2. Research the relevant iOS 15 CarPlay architecture and constraints.
3. Implement and test CarPlay-related functionality incrementally on-device.

## License

BridgeX is licensed under the GNU General Public License, version 3 or (at your option) any later version. See [LICENSE](LICENSE). New source files should carry the SPDX identifier `GPL-3.0-or-later`.
