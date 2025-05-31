//
//  ThemeManager.h
//  Moonlight-ZWM
//
//  Created by True砖家 on 2025.5.25.
//  Copyright © 2025 True砖家 @ Bilibili. All rights reserved.
//

#import "ThemeManager.h"

@implementation ThemeManager

static UIUserInterfaceStyle _privateUserInterfaceStyle = UIUserInterfaceStyleUnspecified;
static UIUserInterfaceStyle _userInterfaceStyle;

+ (UIColor *)getUIStyle{
    if (@available(iOS 13.0, *)) {
        UITraitCollection *traitCollection = [UIScreen mainScreen].traitCollection;
            if(_privateUserInterfaceStyle == UIUserInterfaceStyleUnspecified) {
                _userInterfaceStyle = traitCollection.userInterfaceStyle;
            }
            else _userInterfaceStyle = _privateUserInterfaceStyle;
            return [UIColor clearColor];
    } else {
        return [UIColor clearColor];
    }
}



+ (UIUserInterfaceStyle)userInterfaceStyle {
    [ThemeManager getUIStyle];
    return _userInterfaceStyle;
}

+ (void)setUserInterfaceStyle:(UIUserInterfaceStyle)style {
    _privateUserInterfaceStyle = style;
    [ThemeManager getUIStyle];
}

+ (UIColor *)appBackgroundColor {
    [ThemeManager getUIStyle];
    switch (self.userInterfaceStyle) {
        case UIUserInterfaceStyleLight:
            return [UIColor colorWithRed:242.0/255.0 green:242.0/255.0 blue:247.0/255.0 alpha:1.0];
            break;
        case UIUserInterfaceStyleDark:
        default:
            return [UIColor colorWithRed:28.0/255.0 green:28.0/255.0 blue:30.0/255.0 alpha:1.0];
            break;
    }
}

+ (UIColor *)widgetBackgroundColor {
    [ThemeManager getUIStyle];
    switch (self.userInterfaceStyle) {
        case UIUserInterfaceStyleLight:
            return [UIColor whiteColor];
            break;
        case UIUserInterfaceStyleDark:
        default:
            return [UIColor colorWithRed:44.0/255.0 green:44.0/255.0 blue:46.0/255.0 alpha:1.0];
            break;
    }
}

+ (UIColor *)separatorColor {
    [ThemeManager getUIStyle];
        switch (self.userInterfaceStyle) {
            case UIUserInterfaceStyleLight:
                NSLog(@"themeLightSP");
                return [UIColor colorWithWhite:0.1 alpha:0.28];
                break;
            case UIUserInterfaceStyleDark:
            default:
                NSLog(@"themeDarkSP");
                return [UIColor colorWithWhite:0.28 alpha:1.0];
                break;
        }
    }


+ (UIColor *)textColor {
    [ThemeManager getUIStyle];
        switch (self.userInterfaceStyle) {
        case UIUserInterfaceStyleLight:
                NSLog(@"themeLightTX");
            return [UIColor blackColor];
            break;
        case UIUserInterfaceStyleDark:
        default:
                NSLog(@"themeDarkTX");
            return [UIColor whiteColor];
            break;
    }
}

+ (UIColor *)appPrimaryColor {
    return [UIColor colorWithRed:0.0 green:0.48 blue:1.0 alpha:1.0]; // #0A84FF
}

+ (UIColor *)appSecondaryColor {
    return [UIColor colorWithRed:0.0 green:0.48 blue:1.0 alpha:1.0]; // 可换其他常用色
}

+ (UIColor *)appPrimaryColorWithAlpha {
    return [[ThemeManager appPrimaryColor] colorWithAlphaComponent:0.24]; // #0A84FF
}

+ (UIColor *)textColorGray{
    return [UIColor colorWithRed:0.55 green:0.55 blue:0.6 alpha:0.95];
}

+ (UIColor *)lowProfileGray{
    return [UIColor colorWithRed:0.65 green:0.65 blue:0.65 alpha:0.4];
}


@end
