//
//  BridgeXStatusClient.m
//  BridgeX
//

#import "BridgeXStatusClient.h"
#import <notify.h>
#import <stdint.h>
#import <stdlib.h>

static const char * const kBridgeXStatusRequest = "com.tego.bridgex.status.request";
static const char * const kBridgeXStatusResponse = "com.tego.bridgex.status.response";
static const char * const kBridgeXSettingsChanged = "com.tego.bridgex.settings.changed";
static const char * const kBridgeXSettingsAcknowledged = "com.tego.bridgex.settings.acknowledged";
static const char * const kBridgeXSettingsReadRequest = "com.tego.bridgex.settings.read";
static const char * const kBridgeXSettingsReadResponse = "com.tego.bridgex.settings.read.response";
static const char * const kBridgeXSettingsDidChange = "com.tego.bridgex.settings.didChange";

@interface BridgeXStatusClient ()
@property (nonatomic, assign) int requestToken;
@property (nonatomic, assign) int responseToken;
@property (nonatomic, assign) int settingsToken;
@property (nonatomic, assign) int settingsAckToken;
@property (nonatomic, assign) int settingsReadToken;
@property (nonatomic, assign) int settingsReadResponseToken;
@property (nonatomic, assign) int settingsChangedToken;
@property (nonatomic, assign) uint64_t activeNonce;
@property (nonatomic, assign) uint64_t activeSettingsRequestID;
@property (nonatomic, assign) uint64_t activeSettingsReadID;
@property (nonatomic, assign) uint64_t nextSettingsRequestID;
@property (nonatomic, assign) BOOL pendingSettingsRefresh;
@property (nonatomic, copy) void (^completion)(BOOL connected);
@property (nonatomic, copy) void (^settingsCompletion)(BOOL saved);
@property (nonatomic, copy) void (^settingsReadCompletion)(BOOL enabled, BOOL available);
@property (nonatomic, copy) void (^settingsChangedHandler)(BOOL enabled, BOOL available);
- (void)refreshSettingsAfterChangeNotification;
- (void)finishSettingsRead:(BOOL)enabled available:(BOOL)available requestID:(uint64_t)requestID;
@end

@implementation BridgeXStatusClient

+ (instancetype)sharedClient {
    static BridgeXStatusClient *client;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{ client = [[BridgeXStatusClient alloc] init]; });
    return client;
}

- (instancetype)init {
    self = [super init];
    if (self) {
        _requestToken = _responseToken = _settingsToken = _settingsAckToken = -1;
        _settingsReadToken = _settingsReadResponseToken = -1;
        _settingsChangedToken = -1;

        uint32_t result = notify_register_check(kBridgeXStatusRequest, &_requestToken);
        if (result != NOTIFY_STATUS_OK) _requestToken = -1;

        result = notify_register_dispatch(kBridgeXStatusResponse, &_responseToken,
            dispatch_get_main_queue(), ^(int token) {
                uint64_t nonce = 0;
                if (notify_get_state(token, &nonce) == NOTIFY_STATUS_OK &&
                    nonce != 0 && nonce == self.activeNonce) {
                    [self finishCheck:YES nonce:nonce];
                }
            });
        if (result != NOTIFY_STATUS_OK) _responseToken = -1;

        result = notify_register_check(kBridgeXSettingsChanged, &_settingsToken);
        if (result != NOTIFY_STATUS_OK) _settingsToken = -1;

        result = notify_register_dispatch(kBridgeXSettingsAcknowledged, &_settingsAckToken,
            dispatch_get_main_queue(), ^(int token) {
                uint64_t state = 0;
                if (notify_get_state(token, &state) != NOTIFY_STATUS_OK) return;
                uint64_t requestID = state >> 2;
                if (requestID == self.activeSettingsRequestID && requestID != 0) {
                    [self finishSettings:((state & 2ULL) != 0)
                               requestID:requestID];
                }
            });
        if (result != NOTIFY_STATUS_OK) _settingsAckToken = -1;

        result = notify_register_check(kBridgeXSettingsReadRequest, &_settingsReadToken);
        if (result != NOTIFY_STATUS_OK) _settingsReadToken = -1;

        result = notify_register_dispatch(kBridgeXSettingsReadResponse,
            &_settingsReadResponseToken, dispatch_get_main_queue(), ^(int token) {
                uint64_t state = 0;
                if (notify_get_state(token, &state) != NOTIFY_STATUS_OK) return;
                uint64_t requestID = state >> 2;
                if (requestID == self.activeSettingsReadID && requestID != 0) {
                    BOOL available = (state & 2ULL) != 0;
                    BOOL enabled = (state & 1ULL) != 0;
                    [self finishSettingsRead:enabled available:available requestID:requestID];
                }
            });
        if (result != NOTIFY_STATUS_OK) _settingsReadResponseToken = -1;
    }
    return self;
}

- (void)observeVerboseDiagnosticsChangesWithHandler:(void (^)(BOOL, BOOL))handler {
    self.settingsChangedHandler = handler;
    if (self.settingsChangedToken >= 0) return;

    uint32_t result = notify_register_dispatch(kBridgeXSettingsDidChange,
        &_settingsChangedToken, dispatch_get_main_queue(), ^(int token) {
            if (self.settingsReadCompletion) {
                self.pendingSettingsRefresh = YES;
                return;
            }
            [self refreshSettingsAfterChangeNotification];
        });
    if (result != NOTIFY_STATUS_OK) {
        self.settingsChangedToken = -1;
    }
}

- (void)refreshSettingsAfterChangeNotification {
    if (!self.settingsChangedHandler) return;
    [self loadVerboseDiagnosticsEnabledWithCompletion:^(BOOL enabled, BOOL available) {
        void (^handler)(BOOL, BOOL) = self.settingsChangedHandler;
        if (handler) handler(enabled, available);
    }];
}

- (void)finishSettingsRead:(BOOL)enabled
                 available:(BOOL)available
                 requestID:(uint64_t)requestID {
    if (requestID != self.activeSettingsReadID || !self.settingsReadCompletion) return;

    void (^completion)(BOOL, BOOL) = self.settingsReadCompletion;
    self.settingsReadCompletion = nil;
    self.activeSettingsReadID = 0;
    completion(enabled, available);

    if (self.pendingSettingsRefresh) {
        self.pendingSettingsRefresh = NO;
        dispatch_async(dispatch_get_main_queue(), ^{
            [self refreshSettingsAfterChangeNotification];
        });
    }
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
        dispatch_get_main_queue(), ^{ [self finishCheck:NO nonce:nonce]; });
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
    if (self.settingsCompletion) {
        if (completion) completion(NO);
        return;
    }
    self.settingsCompletion = completion;
    if (self.settingsToken < 0 || self.settingsAckToken < 0) {
        [self finishSettings:NO requestID:0];
        return;
    }

    uint64_t requestID = (++self.nextSettingsRequestID) & 0x3fffffffffffffffULL;
    if (requestID == 0) requestID = (++self.nextSettingsRequestID) & 0x3fffffffffffffffULL;
    self.activeSettingsRequestID = requestID;
    uint64_t payload = (requestID << 1) | (enabled ? 1ULL : 0ULL);
    uint32_t result = notify_set_state(self.settingsToken, payload);
    if (result != NOTIFY_STATUS_OK || notify_post(kBridgeXSettingsChanged) != NOTIFY_STATUS_OK) {
        [self finishSettings:NO requestID:requestID];
        return;
    }

    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, 3 * NSEC_PER_SEC),
        dispatch_get_main_queue(), ^{
            [self finishSettings:NO requestID:requestID];
        });
}

- (void)finishSettings:(BOOL)saved requestID:(uint64_t)requestID {
    if (requestID != self.activeSettingsRequestID || !self.settingsCompletion) return;
    void (^completion)(BOOL) = self.settingsCompletion;
    self.settingsCompletion = nil;
    self.activeSettingsRequestID = 0;
    completion(saved);
}

- (void)loadVerboseDiagnosticsEnabledWithCompletion:(void (^)(BOOL, BOOL))completion {
    if (self.settingsReadCompletion) {
        if (completion) completion(NO, NO);
        return;
    }
    if (self.settingsReadToken < 0 || self.settingsReadResponseToken < 0) {
        if (completion) completion(NO, NO);
        return;
    }
    uint64_t requestID = (((uint64_t)arc4random() << 32) | arc4random()) & 0x3fffffffffffffffULL;
    if (requestID == 0) requestID = 1;
    self.activeSettingsReadID = requestID;
    self.settingsReadCompletion = completion;
    if (notify_set_state(self.settingsReadToken, requestID) != NOTIFY_STATUS_OK ||
        notify_post(kBridgeXSettingsReadRequest) != NOTIFY_STATUS_OK) {
        [self finishSettingsRead:NO available:NO requestID:requestID];
        return;
    }
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, 3 * NSEC_PER_SEC),
        dispatch_get_main_queue(), ^{
            if (self.activeSettingsReadID != requestID) return;
            [self finishSettingsRead:NO available:NO requestID:requestID];
        });
}

@end
