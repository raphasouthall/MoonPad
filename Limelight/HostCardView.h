//
//  HostCardView.h
//  Moonlight-ZWM
//
//  Created by True砖家 on 5/18/25.
//  Copyright © 2025 True砖家 @ Bilibili. All rights reserved.
//


#import <UIKit/UIKit.h>
#import "TemporaryHost.h"

@protocol HostCallback <NSObject>

- (void) hostClicked:(TemporaryHost*)host view:(UIView*)view;
- (void) hostLongClicked:(TemporaryHost*)host view:(UIView*)view;
- (void) addHostClicked;

@end

@interface HostCardView : UIView
@property (nonatomic, assign) CGFloat sizeFactor;
@property (nonatomic, readonly) CGSize size;


- (void)resizeBySizeFactor:(CGFloat)factor;
- (id) initWithHost:(TemporaryHost*)host;
- (id) initWithHost:(TemporaryHost*)host andSizeFactor:(CGFloat)sizeFactor;

@end

