//
//  UIColor+Theme.h
//  Moonlight-ZWM
//
//  Created by True砖家 on 2025.5.25.
//  Copyright © 2025 True砖家 @ Bilibili. All rights reserved.
//

#import "UIColor+Theme.h"

@implementation UIColor (Theme)

+ (UIColor *)appPrimaryColor {
    return [UIColor colorWithRed:0.0 green:0.48 blue:1.0 alpha:1.0]; // #0A84FF
}

+ (UIColor *)appSecondaryColor {
    return [UIColor colorWithRed:0.0 green:0.48 blue:1.0 alpha:1.0]; // 可换其他常用色
}

+ (UIColor *)appPrimaryColorWithAlpha {
    return [[UIColor appPrimaryColor] colorWithAlphaComponent:0.24]; // #0A84FF
}


+ (UIColor *)widgetBackgroundColorDark{
    return [UIColor colorWithRed:44.0/255.0 green:44.0/255.0 blue:46.0/255.0 alpha:1.0];
}

+ (UIColor *)widgetBackgroundColorLight{
    return [UIColor colorWithRed:242.0/255.0 green:242.0/255.0 blue:247.0/255.0 alpha:1.0];
}

+ (UIColor *)separatorColorDark{
    return [UIColor colorWithWhite:0.28 alpha:1.0];
}

+ (UIColor *)separatorColorLight{
    return [UIColor colorWithWhite:0.1 alpha:0.28];
}

+ (UIColor *)textColorDark{
    return [UIColor whiteColor];
}

+ (UIColor *)textColorLight{
    return [UIColor blackColor];
}

+ (UIColor *)textColorGray{
    return [UIColor colorWithRed:0.55 green:0.55 blue:0.6 alpha:0.95];
}

+ (UIColor *)lowProfileGray{
    return [UIColor colorWithRed:0.65 green:0.65 blue:0.65 alpha:0.4];
}

+ (UIColor *)appBackgroundColorDark {
    return [UIColor colorWithRed:28.0/255.0 green:28.0/255.0 blue:30.0/255.0 alpha:1.0];
}

+ (UIColor *)appBackgroundColorLight {
    return [UIColor whiteColor];
}


@end
