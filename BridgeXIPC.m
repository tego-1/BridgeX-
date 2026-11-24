// SPDX-License-Identifier: GPL-3.0-or-later
#import "BridgeXIPC.h"
#import <notify.h>

static const char * const kBridgeXStatusRequest =
    "com.tego.bridgex.status.request";
static const char * const kBridgeXStatusResponse =
    "com.tego.bridgex.status.response";

static int gBridgeXRequestToken = -1;
static int gBridgeXResponseToken = -1;

static void BridgeXHandleStatusRequest(int token) {
    uint64_t requestNonce = 0;
    uint32_t result = notify_get_state(token, &requestNonce);

    if (result != 0 || requestNonce == 0) {
        NSLog(@"[BridgeX][IPC] Ignored invalid status request (result=%u).", result);
        return;
    }

    // Echo the request nonce. The companion app only accepts a response
    // matching its current request, so stale responses cannot mark it online.
    result = notify_set_state(gBridgeXResponseToken, requestNonce);
    if (result != 0) {
        NSLog(@"[BridgeX][IPC] Failed to publish status response (result=%u).", result);
        return;
    }

    result = notify_post(kBridgeXStatusResponse);
    if (result != 0) {
        NSLog(@"[BridgeX][IPC] Failed to post status response (result=%u).", result);
        return;
    }

    NSLog(@"[BridgeX][IPC] Responded to companion status request.");
}

void BridgeXStartStatusIPC(void) {
    if (gBridgeXRequestToken >= 0) {
        return;
    }

    uint32_t result = notify_register_check(
        kBridgeXStatusResponse,
        &gBridgeXResponseToken
    );
    if (result != 0) {
        NSLog(@"[BridgeX][IPC] Could not register response state (result=%u).", result);
        gBridgeXResponseToken = -1;
        return;
    }

    result = notify_register_dispatch(
        kBridgeXStatusRequest,
        &gBridgeXRequestToken,
        dispatch_get_main_queue(),
        ^(int token) {
            BridgeXHandleStatusRequest(token);
        }
    );

    if (result != 0) {
        NSLog(@"[BridgeX][IPC] Could not register status listener (result=%u).", result);
        gBridgeXRequestToken = -1;
        return;
    }

    NSLog(@"[BridgeX][IPC] Status listener ready.");
}
