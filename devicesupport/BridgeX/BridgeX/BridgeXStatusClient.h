//
//  BridgeXStatusClient.h
//  BridgeX
//
//  Created by William Stephenson on 11/24/26.
//


#import <Foundation/Foundation.h>

@interface BridgeXStatusClient : NSObject

+ (instancetype)sharedClient;

- (void)checkStatusWithCompletion:(void (^)(BOOL connected))completion;

@end
