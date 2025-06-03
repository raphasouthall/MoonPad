//
//  SettingsViewController.h
//  Moonlight
//
//  Created by Diego Waxemberg on 10/27/14.
//  Copyright (c) 2014 Moonlight Stream. All rights reserved.
//
//  Modified by True砖家 since 2024.6.1
//  Copyright © 2024 True砖家 @ Bilibili. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "AppDelegate.h"
#import "CustomOSCViewControl/LayoutOnScreenControlsViewController.h"
#import "MainFrameViewController.h"
#import "CustomEdgeSlideGestureRecognizer.h"

@interface SettingsViewController : UIViewController <RearNavigationBarMenuDelegate>
@property (strong, nonatomic) IBOutlet UINavigationBar *navigationBar;
@property (strong, nonatomic) IBOutlet UIStackView *resolutionStack;
@property (strong, nonatomic) IBOutlet UIStackView *fpsStack;
@property (strong, nonatomic) IBOutlet UIStackView *bitrateStack;
@property (strong, nonatomic) IBOutlet UIStackView *touchModeStack;
@property (strong, nonatomic) IBOutlet UIStackView *asyncTouchStack;
@property (strong, nonatomic) IBOutlet UIStackView *pointerVelocityDividerStack;
@property (strong, nonatomic) IBOutlet UIStackView *pointerVelocityFactorStack;
@property (strong, nonatomic) IBOutlet UIStackView *touchMoveEventIntervalStack;
@property (strong, nonatomic) IBOutlet UIStackView *mousePointerVelocityStack;
@property (strong, nonatomic) IBOutlet UIStackView *onScreenWidgetStack;
@property (strong, nonatomic) IBOutlet UIStackView *keyboardToggleFingerNumStack;
@property (strong, nonatomic) IBOutlet UIStackView *liftStreamViewForKeyboardStack;
@property (strong, nonatomic) IBOutlet UIStackView *showKeyboardToolbarStack;
@property (strong, nonatomic) IBOutlet UIStackView *slideToSettingsScreenEdgeStack;
@property (strong, nonatomic) IBOutlet UIStackView *slideToCmdToolScreenEdgeStack;
@property (strong, nonatomic) IBOutlet UIStackView *slideToSettingsDistanceStack;
@property (strong, nonatomic) IBOutlet UIStackView *optimizeSettingsStack;
@property (strong, nonatomic) IBOutlet UIStackView *multiControllerStack;
@property (strong, nonatomic) IBOutlet UIStackView *swapAbaxyStack;
@property (strong, nonatomic) IBOutlet UIStackView *audioOnPcStack;
@property (strong, nonatomic) IBOutlet UIStackView *codecStack;
@property (strong, nonatomic) IBOutlet UIStackView *yuv444Stack;
@property (strong, nonatomic) IBOutlet UIStackView *HdrStack;
@property (strong, nonatomic) IBOutlet UIStackView *framepacingStack;
@property (strong, nonatomic) IBOutlet UIStackView *reverseMouseWheelDirectionStack;
@property (strong, nonatomic) IBOutlet UIStackView *citrixX1MouseStack;
@property (strong, nonatomic) IBOutlet UIStackView *statsOverlayStack;
@property (strong, nonatomic) IBOutlet UIStackView *unlockDisplayOrientationStack;
@property (strong, nonatomic) IBOutlet UIStackView *externalDisplayModeStack;
@property (strong, nonatomic) IBOutlet UIStackView *localMousePointerModeStack;

@property (strong, nonatomic) IBOutlet UILabel *bitrateLabel;
@property (strong, nonatomic) IBOutlet UISlider *bitrateSlider;
@property (strong, nonatomic) IBOutlet UISegmentedControl *framerateSelector;
@property (strong, nonatomic) IBOutlet UISegmentedControl *resolutionSelector;
@property (strong, nonatomic) IBOutlet UIView *resolutionDisplayView;
@property (strong, nonatomic) IBOutlet UILabel *touchModeLabel;
@property (strong, nonatomic) IBOutlet UISegmentedControl *touchModeSelector;
@property (strong, nonatomic) IBOutlet UILabel *onscreenControllerLabel;
@property (strong, nonatomic) IBOutlet UISegmentedControl *onscreenControlSelector;
@property (strong, nonatomic) IBOutlet UISegmentedControl *asyncNativeTouchPrioritySelector;
@property (strong, nonatomic) IBOutlet UISegmentedControl *optimizeSettingsSelector;
@property (strong, nonatomic) IBOutlet UISegmentedControl *multiControllerSelector;
@property (strong, nonatomic) IBOutlet UISegmentedControl *swapABXYButtonsSelector;
@property (strong, nonatomic) IBOutlet UISegmentedControl *audioOnPCSelector;
@property (strong, nonatomic) IBOutlet UISegmentedControl *codecSelector;
@property (strong, nonatomic) IBOutlet UISegmentedControl *yuv444Selector;
@property (strong, nonatomic) IBOutlet UISegmentedControl *hdrSelector;
@property (strong, nonatomic) IBOutlet UISegmentedControl *framePacingSelector;
@property (strong, nonatomic) IBOutlet UISegmentedControl *btMouseSelector;
@property (strong, nonatomic) IBOutlet UISegmentedControl *reverseMouseWheelDirectionSelector;
@property (strong, nonatomic) IBOutlet UISegmentedControl *statsOverlaySelector;
@property (strong, nonatomic) IBOutlet UIScrollView *scrollView;
@property (strong, nonatomic) IBOutlet UILabel *keyboardToggleFingerNumLabel;
@property (strong, nonatomic) IBOutlet UISlider *keyboardToggleFingerNumSlider;
@property (strong, nonatomic) IBOutlet UISegmentedControl *liftStreamViewForKeyboardSelector;
@property (strong, nonatomic) IBOutlet UISegmentedControl *showKeyboardToolbarSelector;
@property (strong, nonatomic) IBOutlet UISegmentedControl *slideToSettingsScreenEdgeSelector;

@property (strong, nonatomic) IBOutlet UILabel *touchMoveEventIntervalLabel;
@property (strong, nonatomic) IBOutlet UISlider *touchMoveEventIntervalSlider;
@property (strong, nonatomic) IBOutlet UILabel *slideToSettingsScreenEdgeUILabel;
@property (strong, nonatomic) IBOutlet UISegmentedControl *cmdToolScreenEdgeSelector;
@property (strong, nonatomic) IBOutlet UILabel *slideToSettingsDistanceUILabel;
@property (strong, nonatomic) IBOutlet UISlider *slideToMenuDistanceSlider;
@property (strong, nonatomic) IBOutlet UISlider *pointerVelocityModeDividerSlider;
@property (strong, nonatomic) IBOutlet UILabel *pointerVelocityModeDividerUILabel;
@property (strong, nonatomic) IBOutlet UISlider *touchPointerVelocityFactorSlider;
@property (strong, nonatomic) IBOutlet UILabel *touchPointerVelocityFactorUILabel;
@property (strong, nonatomic) IBOutlet UISlider *mousePointerVelocityFactorSlider;
@property (strong, nonatomic) IBOutlet UILabel *mousePointerVelocityFactorUILabel;
@property (strong, nonatomic) IBOutlet UISegmentedControl *unlockDisplayOrientationSelector;
@property (strong, nonatomic) IBOutlet UIButton *backToStreamingButton;
@property (strong, nonatomic) LayoutOnScreenControlsViewController *layoutOnScreenControlsVC;
@property (nonatomic, strong) MainFrameViewController *mainFrameViewController;

@property (strong, nonatomic) IBOutlet UISegmentedControl *externalDisplayModeSelector;
@property (strong, nonatomic) IBOutlet UISegmentedControl *localMousePointerModeSelector;

#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wunguarded-availability"

// This is okay because it's just an enum and access uses @available checks
@property(nonatomic) UIUserInterfaceStyle overrideUserInterfaceStyle;

#pragma clang diagnostic pop

typedef NS_ENUM(NSInteger, SettingsMenuMode) {
    AllSettings,
    FavoriteSettings,
};

- (void)saveSettings;
+ (bool)isLandscapeNow;
- (void)updateResolutionTable;
- (void)widget:(UISlider*)widget setEnabled:(bool)enabled;
- (void)updateTheme;


@end
