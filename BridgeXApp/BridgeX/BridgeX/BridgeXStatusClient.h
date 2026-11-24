//
//  BridgeXStatusClient.h
//  BridgeX
//

#import <Foundation/Foundation.h>

@interface BridgeXStatusClient : NSObject

+ (instancetype)sharedClient;

- (void)checkStatusWithCompletion:(void (^)(BOOL connected))completion;
- (void)setVerboseDiagnosticsEnabled:(BOOL)enabled
                          completion:(void (^)(BOOL saved))completion;
- (void)loadVerboseDiagnosticsEnabledWithCompletion:(void (^)(BOOL enabled, BOOL available))completion;
- (void)observeVerboseDiagnosticsChangesWithHandler:(void (^)(BOOL enabled, BOOL available))handler;

@end
