//
//  HostCardView.h
//  Moonlight-ZWM
//
//  Created by True砖家 on 5/18/25.
//  Copyright © 2025 True砖家 @ Bilibili. All rights reserved.
//


#import <UIKit/UIKit.h>
#import "TemporaryHost.h"


@protocol HostCardButtonActionDelegate <NSObject>
- (void)leftButtonTappedForHost:(TemporaryHost *)host;
- (void)rightButtonTappedForHost:(TemporaryHost *)host;
- (void)pairButtonTappedForHost:(TemporaryHost *)host;
@end


@interface HostCardView : UIView
@property (nonatomic, assign) CGFloat sizeFactor;
@property (nonatomic, readonly) CGSize size;
@property (nonatomic, weak) id<HostCardButtonActionDelegate> delegate; // Delegate property

- (void)resizeBySizeFactor:(CGFloat)factor;
- (id) initWithHost:(TemporaryHost*)host;
- (id) initWithHost:(TemporaryHost*)host andSizeFactor:(CGFloat)sizeFactor;

@end

