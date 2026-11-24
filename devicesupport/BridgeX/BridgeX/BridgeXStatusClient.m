//
//  BridgeXStatusClient.m
//  BridgeX
//

#import "BridgeXStatusClient.h"
#import <notify.h>
#import <stdint.h>
#import <stdlib.h>

static const char * const kBridgeXStatusRequest =
    "com.tego.bridgex.status.request";
static const char * const kBridgeXStatusResponse =
    "com.tego.bridgex.status.response";
static const char * const kBridgeXSettingsChanged =
    "com.tego.bridgex.settings.changed";
static const char * const kBridgeXSettingsAcknowledged =
    "com.tego.bridgex.settings.acknowledged";

@interface BridgeXStatusClient ()

@property (nonatomic, assign) int requestToken;
@property (nonatomic, assign) int responseToken;
@property (nonatomic, assign) int settingsToken;
@property (nonatomic, assign) int settingsAckToken;
@property (nonatomic, assign) uint64_t activeNonce;
@property (nonatomic, assign) uint64_t activeSettingsFlags;
@property (nonatomic, copy) void (^completion)(BOOL connected);
@property (nonatomic, copy) void (^settingsCompletion)(BOOL saved);

@end

@implementation BridgeXStatusClient

+ (instancetype)sharedClient {
    static BridgeXStatusClient *client;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        client = [[BridgeXStatusClient alloc] init];
    });
    return client;
}

- (instancetype)init {
    self = [super init];
    if (self) {
        _requestToken = -1;
        _responseToken = -1;
        _settingsToken = -1;
        _settingsAckToken = -1;

        uint32_t result = notify_register_check(kBridgeXStatusRequest, &_requestToken);
        if (result != NOTIFY_STATUS_OK) _requestToken = -1;

        result = notify_register_dispatch(
            kBridgeXStatusResponse,
            &_responseToken,
            dispatch_get_main_queue(),
            ^(int token) {
                uint64_t responseNonce = 0;
                uint32_t status = notify_get_state(token, &responseNonce);
                if (status == NOTIFY_STATUS_OK &&
                    responseNonce != 0 &&
                    responseNonce == self.activeNonce) {
                    [self finishCheck:YES nonce:responseNonce];
                }
            }
        );
        if (result != NOTIFY_STATUS_OK) _responseToken = -1;

        result = notify_register_check(kBridgeXSettingsChanged, &_settingsToken);
        if (result != NOTIFY_STATUS_OK) _settingsToken = -1;

        result = notify_register_dispatch(
            kBridgeXSettingsAcknowledged,
            &_settingsAckToken,
            dispatch_get_main_queue(),
            ^(int token) {
                uint64_t acknowledgedFlags = 0;
                uint32_t status = notify_get_state(token, &acknowledgedFlags);
                if (status == NOTIFY_STATUS_OK &&
                    acknowledgedFlags == self.activeSettingsFlags) {
                    [self finishSettings:YES];
                }
            }
        );
        if (result != NOTIFY_STATUS_OK) _settingsAckToken = -1;
    }
    return self;
}

- (void)checkStatusWithCompletion:(void (^)(BOOL))completion {
    self.completion = completion;
    if (self.requestToken < 0 || self.responseToken < 0) {
        [self finishCheck:NO nonce:0];
        return;
    }

    uint64_t nonce = ((uint64_t)arc4random() << 32) | arc4random();
    if (nonce == 0) nonce = 1;
    self.activeNonce = nonce;

    uint32_t result = notify_set_state(self.requestToken, nonce);
    if (result != NOTIFY_STATUS_OK || notify_post(kBridgeXStatusRequest) != NOTIFY_STATUS_OK) {
        [self finishCheck:NO nonce:nonce];
        return;
    }

    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, 2 * NSEC_PER_SEC),
                   dispatch_get_main_queue(), ^{
        [self finishCheck:NO nonce:nonce];
    });
}

- (void)finishCheck:(BOOL)connected nonce:(uint64_t)nonce {
    if (nonce != 0 && nonce != self.activeNonce) return;
    if (!self.completion) return;
    void (^completion)(BOOL) = self.completion;
    self.completion = nil;
    completion(connected);
}

- (void)setVerboseDiagnosticsEnabled:(BOOL)enabled
                          completion:(void (^)(BOOL))completion {
    self.settingsCompletion = completion;
    if (self.settingsToken < 0 || self.settingsAckToken < 0) {
        [self finishSettings:NO];
        return;
    }

    uint64_t flags = enabled ? 1ULL : 0ULL;
    self.activeSettingsFlags = flags;
    uint32_t result = notify_set_state(self.settingsToken, flags);
    if (result != NOTIFY_STATUS_OK ||
        notify_post(kBridgeXSettingsChanged) != NOTIFY_STATUS_OK) {
        [self finishSettings:NO];
        return;
    }

    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, 2 * NSEC_PER_SEC),
                   dispatch_get_main_queue(), ^{
        [self finishSettings:NO];
    });
}

- (void)finishSettings:(BOOL)saved {
    if (!self.settingsCompletion) return;
    void (^completion)(BOOL) = self.settingsCompletion;
    self.settingsCompletion = nil;
    completion(saved);
}

@end
