// SPDX-License-Identifier: GPL-3.0-or-later
#import <Foundation/Foundation.h>

// This constructor only confirms that the dynamic library was loaded.
// It intentionally does not hook SpringBoard or implement CarPlay behavior.
__attribute__((constructor))
static void BridgeXInitialize(void) {
    NSLog(@"[BridgeX] Foundation loaded (no CarPlay integration implemented).");
}
