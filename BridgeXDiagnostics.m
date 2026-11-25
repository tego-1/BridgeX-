// SPDX-License-Identifier: GPL-3.0-or-later
#import "BridgeXDiagnostics.h"
#import <CoreFoundation/CoreFoundation.h>

// Read the shared preference once during startup. A missing preference is
// treated as disabled so diagnostics remain opt-in by default.
static BOOL BridgeXVerboseDiagnosticsEnabled(void) {
    CFPropertyListRef value = CFPreferencesCopyAppValue(
        CFSTR("VerboseDiagnosticsEnabled"),
        CFSTR("com.tego.bridgex"));

    BOOL enabled = value != NULL &&
                   CFGetTypeID(value) == CFBooleanGetTypeID() &&
                   CFBooleanGetValue((CFBooleanRef)value);

    if (value != NULL) {
        CFRelease(value);
    }

    return enabled;
}

void BridgeXLogStartupDiagnostics(void) {
    @autoreleasepool {
        if (!BridgeXVerboseDiagnosticsEnabled()) {
            return;
        }

        NSProcessInfo *processInfo = [NSProcessInfo processInfo];
        NSString *processName = processInfo.processName ?: @"unknown";
        NSString *bundleIdentifier = [NSBundle mainBundle].bundleIdentifier ?: @"unknown";
        NSOperatingSystemVersion osVersion = processInfo.operatingSystemVersion;

#if defined(__arm64e__)
        NSString *architecture = @"arm64e";
#elif defined(__arm64__)
        NSString *architecture = @"arm64";
#else
        NSString *architecture = @"unknown";
#endif

        NSLog(@"[BridgeX][Diagnostics] ===== Runtime report =====");
        NSLog(@"[BridgeX][Diagnostics] Process: %@", processName);
        NSLog(@"[BridgeX][Diagnostics] Bundle: %@", bundleIdentifier);
        NSLog(@"[BridgeX][Diagnostics] OS: %ld.%ld.%ld",
              (long)osVersion.majorVersion,
              (long)osVersion.minorVersion,
              (long)osVersion.patchVersion);
        NSLog(@"[BridgeX][Diagnostics] Architecture: %@", architecture);
        NSLog(@"[BridgeX][Diagnostics] System uptime: %.1f seconds",
              processInfo.systemUptime);
        NSLog(@"[BridgeX][Diagnostics] ==========================");
    }
}
