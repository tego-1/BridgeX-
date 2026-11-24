// SPDX-License-Identifier: GPL-3.0-or-later
#import "BridgeXDiagnostics.h"

void BridgeXLogStartupDiagnostics(void) {
    @autoreleasepool {
        NSProcessInfo *processInfo = [NSProcessInfo processInfo];
        NSString *processName = processInfo.processName ?: @"unknown";
        NSString *bundleIdentifier = [NSBundle mainBundle].bundleIdentifier ?: @"unknown";
        NSOperatingSystemVersion osVersion = processInfo.operatingSystemVersion;

#if defined(__arm64__)
        NSString *architecture = @"arm64";
#elif defined(__arm64e__)
        NSString *architecture = @"arm64e";
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
        NSLog(@"[BridgeX][Diagnostics] Process uptime: %.1f seconds",
              processInfo.systemUptime);
        NSLog(@"[BridgeX][Diagnostics] ==========================");
    }
}
