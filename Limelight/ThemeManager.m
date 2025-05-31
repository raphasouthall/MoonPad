//
//  ThemeManager.h
//  Moonlight-ZWM
//
//  Created by True砖家 on 2025.5.25.
//  Copyright © 2025 True砖家 @ Bilibili. All rights reserved.
//

#import "ThemeManager.h"

@implementation ThemeManager

static UIUserInterfaceStyle _userInterfaceStyle = UIUserInterfaceStyleLight;

+ (UIUserInterfaceStyle)userInterfaceStyle {
    return _userInterfaceStyle;
}

+ (void)setUserInterfaceStyle:(UIUserInterfaceStyle)style {
    _userInterfaceStyle = style;
}

+ (UIColor *)appBackgroundColor {
    if (@available(iOS 13.0, *)) {
        return [UIColor colorWithDynamicProvider:^UIColor *(UITraitCollection *traitCollection) {
            UIUserInterfaceStyle style = self.userInterfaceStyle;
            if (style == UIUserInterfaceStyleUnspecified) {
                // 跟随系统
                style = traitCollection.userInterfaceStyle;
            }
            switch (style) {
                case UIUserInterfaceStyleLight:
                    return [UIColor colorWithRed:242.0/255.0 green:242.0/255.0 blue:247.0/255.0 alpha:1.0];
                case UIUserInterfaceStyleDark:
                default:
                    return [UIColor colorWithRed:28.0/255.0 green:28.0/255.0 blue:30.0/255.0 alpha:1.0];
            }
        }];
    } else {
        switch (self.userInterfaceStyle) {
            case UIUserInterfaceStyleLight:
                return [UIColor colorWithRed:242.0/255.0 green:242.0/255.0 blue:247.0/255.0 alpha:1.0];
            case UIUserInterfaceStyleDark:
            default:
                return [UIColor colorWithRed:28.0/255.0 green:28.0/255.0 blue:30.0/255.0 alpha:1.0];
        }
    }
}


+ (UIColor *)widgetBackgroundColor {
    if (@available(iOS 13.0, *)) {
        return [UIColor colorWithDynamicProvider:^UIColor *(UITraitCollection *traitCollection) {
            UIUserInterfaceStyle style = self.userInterfaceStyle;
            if (style == UIUserInterfaceStyleUnspecified) {
                // 跟随系统
                style = traitCollection.userInterfaceStyle;
            }
            switch (style) {
                case UIUserInterfaceStyleLight:
                    return [UIColor whiteColor];
                case UIUserInterfaceStyleDark:
                default:
                    return [UIColor colorWithRed:44.0/255.0 green:44.0/255.0 blue:46.0/255.0 alpha:1.0];
            }
        }];
    } else {
        switch (self.userInterfaceStyle) {
            case UIUserInterfaceStyleLight:
                return [UIColor whiteColor];
            case UIUserInterfaceStyleDark:
            default:
                return [UIColor colorWithRed:44.0/255.0 green:44.0/255.0 blue:46.0/255.0 alpha:1.0];
        }
    }
}

+ (UIColor *)separatorColor {
    if (@available(iOS 13.0, *)) {
        return [UIColor colorWithDynamicProvider:^UIColor *(UITraitCollection *traitCollection) {
            UIUserInterfaceStyle style = self.userInterfaceStyle;
            if (style == UIUserInterfaceStyleUnspecified) {
                // 跟随系统
                style = traitCollection.userInterfaceStyle;
            }
            switch (style) {
                case UIUserInterfaceStyleLight:
                    return [UIColor colorWithWhite:0.1 alpha:0.28];
                case UIUserInterfaceStyleDark:
                default:
                    return [UIColor colorWithWhite:0.28 alpha:1.0];
            }
        }];
    } else {
        switch (self.userInterfaceStyle) {
            case UIUserInterfaceStyleLight:
                return [UIColor colorWithWhite:0.1 alpha:0.28];
            case UIUserInterfaceStyleDark:
            default:
                return [UIColor colorWithWhite:0.28 alpha:1.0];
        }
    }
}


+ (UIColor *)textColor {
    if (@available(iOS 13.0, *)) {
        return [UIColor colorWithDynamicProvider:^UIColor *(UITraitCollection *traitCollection) {
            UIUserInterfaceStyle style = self.userInterfaceStyle;
            if (style == UIUserInterfaceStyleUnspecified) {
                // 跟随系统
                style = traitCollection.userInterfaceStyle;
            }
            switch (style) {
                case UIUserInterfaceStyleLight:
                    return [UIColor blackColor];
                case UIUserInterfaceStyleDark:
                default:
                    return [UIColor whiteColor];
            }
        }];
    } else {
        switch (self.userInterfaceStyle) {
            case UIUserInterfaceStyleLight:
                return [UIColor blackColor];
            case UIUserInterfaceStyleDark:
            default:
                return [UIColor whiteColor];
        }
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
