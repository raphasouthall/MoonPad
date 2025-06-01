//
//  UIComputerView.h
//  Moonlight
//
//  Created by Diego Waxemberg on 10/22/14.
//  Copyright (c) 2014 Moonlight Stream. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "TemporaryHost.h"

@protocol HostCallback <NSObject>

- (void) noneUserInitiatedHostAction:(TemporaryHost*)host view:(UIView*)view;
- (void) hostCardLongPressed:(TemporaryHost*)host view:(UIView*)view;
- (void) addHostTapped;

@end

#if !TARGET_OS_TV
@interface UIComputerView : UIButton <UIContextMenuInteractionDelegate>
#else
@interface UIComputerView : UIButton
#endif

- (id) initWithComputer:(TemporaryHost*)host andCallback:(id<HostCallback>)callback;
- (id) initForAddWithCallback:(id<HostCallback>)callback;

@end
