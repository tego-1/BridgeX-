// SPDX-License-Identifier: GPL-3.0-or-later
#import <Preferences/PSListController.h>
#import <notify.h>
#import <CoreFoundation/CoreFoundation.h>

static const char * const kBridgeXSettingsDidChange = "com.tego.bridgex.settings.didChange";
static CFStringRef const kBridgeXPreferencesDomain = CFSTR("com.tego.bridgex");

@interface BridgeXRootListController : PSListController
@property (nonatomic, assign) int settingsChangedToken;
@end

@implementation BridgeXRootListController

- (NSArray *)specifiers {
    if (!_specifiers) {
        _specifiers = [self loadSpecifiersFromPlistName:@"Root" target:self];
    }
    return _specifiers;
}

- (void)viewDidLoad {
    [super viewDidLoad];

    self.settingsChangedToken = -1;
    __weak typeof(self) weakSelf = self;
    uint32_t result = notify_register_dispatch(kBridgeXSettingsDidChange,
        &_settingsChangedToken, dispatch_get_main_queue(), ^(int token __unused) {
            [weakSelf reloadSpecifiers];
        });
    if (result != NOTIFY_STATUS_OK) {
        self.settingsChangedToken = -1;
    }
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    [self reloadSpecifiers];
}

- (void)setPreferenceValue:(id)value specifier:(PSSpecifier *)specifier {
    [super setPreferenceValue:value specifier:specifier];

    Boolean saved = CFPreferencesAppSynchronize(kBridgeXPreferencesDomain);
    if (saved) {
        notify_post(kBridgeXSettingsDidChange);
    }
}

- (void)dealloc {
    if (self.settingsChangedToken >= 0) {
        notify_cancel(self.settingsChangedToken);
    }
}

@end
