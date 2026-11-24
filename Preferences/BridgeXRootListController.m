// SPDX-License-Identifier: GPL-3.0-or-later
#import <Preferences/PSListController.h>

@interface BridgeXRootListController : PSListController
@end

@implementation BridgeXRootListController

- (NSArray *)specifiers {
    if (!_specifiers) {
        _specifiers = [self loadSpecifiersFromPlistName:@"Root" target:self];
    }
    return _specifiers;
}

@end
