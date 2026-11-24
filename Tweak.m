// SPDX-License-Identifier: GPL-3.0-or-later
#import <Foundation/Foundation.h>
#import "BridgeXDiagnostics.h"

// Keep the constructor small: initialize diagnostics after the dylib is loaded.
__attribute__((constructor))
static void BridgeXInitialize(void) {
    @autoreleasepool {
        NSLog(@"[BridgeX] Foundation loaded (no CarPlay integration implemented).");
        BridgeXLogStartupDiagnostics();
    }
}
