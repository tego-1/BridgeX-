// SPDX-License-Identifier: GPL-3.0-or-later
#import "BridgeXSettingsIPC.h"
#import <notify.h>
#import <CoreFoundation/CoreFoundation.h>

static const char * const kBridgeXSettingsChanged = "com.tego.bridgex.settings.changed";
static const char * const kBridgeXSettingsAcknowledged = "com.tego.bridgex.settings.acknowledged";
static const char * const kBridgeXSettingsReadRequest = "com.tego.bridgex.settings.read";
static const char * const kBridgeXSettingsReadResponse = "com.tego.bridgex.settings.read.response";
static const CFStringRef kBridgeXPreferencesDomain = CFSTR("com.tego.bridgex");

static int gBridgeXSettingsToken = -1;
static int gBridgeXSettingsAckToken = -1;
static int gBridgeXSettingsReadToken = -1;
static int gBridgeXSettingsReadResponseToken = -1;

static void BridgeXHandleSettingsChange(int token) {
    uint64_t payload = 0;
    uint32_t result = notify_get_state(token, &payload);
    if (result != NOTIFY_STATUS_OK) {
        NSLog(@"[BridgeX][Settings] Could not read settings payload (%u).", result);
        return;
    }

    uint64_t requestID = payload >> 1;
    if (requestID == 0) return;
    Boolean enabled = (payload & 1ULL) != 0;
    CFPreferencesSetAppValue(CFSTR("VerboseDiagnosticsEnabled"),
                             enabled ? kCFBooleanTrue : kCFBooleanFalse,
                             kBridgeXPreferencesDomain);
    Boolean saved = CFPreferencesAppSynchronize(kBridgeXPreferencesDomain);

    uint64_t acknowledgement = (requestID << 2) |
                               (saved ? 2ULL : 0ULL) |
                               (enabled ? 1ULL : 0ULL);
    result = notify_set_state(gBridgeXSettingsAckToken, acknowledgement);
    if (result == NOTIFY_STATUS_OK) result = notify_post(kBridgeXSettingsAcknowledged);

    NSLog(@"[BridgeX][Settings] Request %llu: verbose diagnostics %@, saved %@, ack %u.",
          requestID, enabled ? @"on" : @"off", saved ? @"yes" : @"no", result);
}

static void BridgeXHandleSettingsRead(int token) {
    uint64_t requestID = 0;
    if (notify_get_state(token, &requestID) != NOTIFY_STATUS_OK || requestID == 0) return;

    CFPropertyListRef value = CFPreferencesCopyAppValue(
        CFSTR("VerboseDiagnosticsEnabled"), kBridgeXPreferencesDomain);
    Boolean available = value != NULL && CFGetTypeID(value) == CFBooleanGetTypeID();
    Boolean enabled = available && CFBooleanGetValue((CFBooleanRef)value);
    if (value) CFRelease(value);

    uint64_t response = (requestID << 2) |
                        (available ? 2ULL : 0ULL) |
                        (enabled ? 1ULL : 0ULL);
    uint32_t result = notify_set_state(gBridgeXSettingsReadResponseToken, response);
    if (result == NOTIFY_STATUS_OK) result = notify_post(kBridgeXSettingsReadResponse);
    NSLog(@"[BridgeX][Settings] Read request %llu: available %@, value %@, response %u.",
          requestID, available ? @"yes" : @"no", enabled ? @"on" : @"off", result);
}

void BridgeXStartSettingsIPC(void) {
    if (gBridgeXSettingsToken >= 0) return;

    uint32_t result = notify_register_check(kBridgeXSettingsAcknowledged,
                                            &gBridgeXSettingsAckToken);
    if (result != NOTIFY_STATUS_OK) {
        gBridgeXSettingsAckToken = -1;
        NSLog(@"[BridgeX][Settings] Could not register acknowledgement channel (%u).", result);
        return;
    }

    result = notify_register_check(kBridgeXSettingsReadResponse,
                                   &gBridgeXSettingsReadResponseToken);
    if (result != NOTIFY_STATUS_OK) {
        gBridgeXSettingsReadResponseToken = -1;
        NSLog(@"[BridgeX][Settings] Could not register read response channel (%u).", result);
        return;
    }

    result = notify_register_dispatch(kBridgeXSettingsChanged, &gBridgeXSettingsToken,
        dispatch_get_main_queue(), ^(int token) { BridgeXHandleSettingsChange(token); });
    if (result != NOTIFY_STATUS_OK) {
        gBridgeXSettingsToken = -1;
        NSLog(@"[BridgeX][Settings] Could not register settings listener (%u).", result);
        return;
    }

    result = notify_register_dispatch(kBridgeXSettingsReadRequest, &gBridgeXSettingsReadToken,
        dispatch_get_main_queue(), ^(int token) { BridgeXHandleSettingsRead(token); });
    if (result != NOTIFY_STATUS_OK) {
        gBridgeXSettingsReadToken = -1;
        NSLog(@"[BridgeX][Settings] Could not register settings read listener (%u).", result);
        return;
    }

    NSLog(@"[BridgeX][Settings] Settings listeners ready.");
}
