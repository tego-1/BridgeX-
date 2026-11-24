// SPDX-License-Identifier: GPL-3.0-or-later
#import "BridgeXSettingsIPC.h"
#import <notify.h>
#import <CoreFoundation/CoreFoundation.h>

static const char * const kBridgeXSettingsChanged =
    "com.tego.bridgex.settings.changed";
static const char * const kBridgeXSettingsAcknowledged =
    "com.tego.bridgex.settings.acknowledged";
static const CFStringRef kBridgeXPreferencesDomain =
    CFSTR("com.tego.bridgex");

static int gBridgeXSettingsToken = -1;
static int gBridgeXSettingsAckToken = -1;

static void BridgeXHandleSettingsChange(int token) {
    uint64_t flags = 0;
    uint32_t result = notify_get_state(token, &flags);
    if (result != NOTIFY_STATUS_OK) {
        NSLog(@"[BridgeX][Settings] Could not read settings payload (%u).", result);
        return;
    }

    // Bit 0 controls verbose diagnostic logging for future diagnostic events.
    Boolean verboseDiagnostics = (flags & 1ULL) != 0;
    CFPreferencesSetAppValue(CFSTR("VerboseDiagnosticsEnabled"),
                             verboseDiagnostics ? kCFBooleanTrue : kCFBooleanFalse,
                             kBridgeXPreferencesDomain);
    Boolean saved = CFPreferencesAppSynchronize(kBridgeXPreferencesDomain);

    result = notify_set_state(gBridgeXSettingsAckToken, flags);
    if (result == NOTIFY_STATUS_OK) {
        result = notify_post(kBridgeXSettingsAcknowledged);
    }

    NSLog(@"[BridgeX][Settings] Received settings (verbose diagnostics: %@, saved: %@, ack: %u).",
          verboseDiagnostics ? @"on" : @"off",
          saved ? @"yes" : @"no",
          result);
}

void BridgeXStartSettingsIPC(void) {
    if (gBridgeXSettingsToken >= 0) {
        return;
    }

    uint32_t result = notify_register_check(
        kBridgeXSettingsAcknowledged,
        &gBridgeXSettingsAckToken
    );
    if (result != NOTIFY_STATUS_OK) {
        gBridgeXSettingsAckToken = -1;
        NSLog(@"[BridgeX][Settings] Could not register acknowledgement channel (%u).", result);
        return;
    }

    result = notify_register_dispatch(
        kBridgeXSettingsChanged,
        &gBridgeXSettingsToken,
        dispatch_get_main_queue(),
        ^(int token) {
            BridgeXHandleSettingsChange(token);
        }
    );
    if (result != NOTIFY_STATUS_OK) {
        gBridgeXSettingsToken = -1;
        NSLog(@"[BridgeX][Settings] Could not register settings listener (%u).", result);
        return;
    }

    NSLog(@"[BridgeX][Settings] Settings listener ready.");
}
