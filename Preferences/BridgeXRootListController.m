// SPDX-License-Identifier: GPL-3.0-or-later
#import <Preferences/PSListController.h>
#import <Preferences/PSSpecifier.h>

@interface BridgeXRootListController : PSListController
@end

@implementation BridgeXRootListController

- (NSArray *)specifiers {
    if (!_specifiers) {
        PSSpecifier *statusGroup = [PSSpecifier groupSpecifierWithName:@"Project status"];
        PSSpecifier *statusItem = [PSSpecifier preferenceSpecifierNamed:@"Foundation scaffold only"
                                                                  target:nil
                                                                     set:nil
                                                                     get:nil
                                                                  detail:nil
                                                                    cell:PSStaticTextCell
                                                                    edit:nil];
        _specifiers = [@[statusGroup, statusItem] mutableCopy];
    }
    return _specifiers;
}

@end
