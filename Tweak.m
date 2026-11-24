// SPDX-License-Identifier: GPL-3.0-or-later
#import <Foundation/Foundation.h>
#import "BridgeXDiagnostics.h"
#import "BridgeXIPC.h"

// Keep initialization small and start IPC only after the dylib is loaded.
__attribute__((constructor))
static void BridgeXInitialize(void) {
    @autoreleasepool {
        NSLog(@"[BridgeX] Foundation loaded (no CarPlay integration implemented).");
        BridgeXLogStartupDiagnostics();
        BridgeXStartStatusIPC();
    }
}
