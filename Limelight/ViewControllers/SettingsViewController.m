//
//  SettingsViewController.m
//  Moonlight
//
//  Created by Diego Waxemberg on 10/27/14.
//  Copyright (c) 2014 Moonlight Stream. All rights reserved.
//
//  Modified by True砖家 since 2024.6.1
//  Copyright © 2024 True砖家 @ Bilibili. All rights reserved.
//

#import "SettingsViewController.h"
#import "TemporarySettings.h"
#import "DataManager.h"
#import "MenuSectionView.h"
#import "ThemeManager.h"

#import <UIKit/UIGestureRecognizerSubclass.h>
#import <VideoToolbox/VideoToolbox.h>
#import <AVFoundation/AVFoundation.h>

#import "LocalizationHelper.h"

@implementation SettingsViewController {
    NSInteger _bitrate;
    NSInteger _lastSelectedResolutionIndex;
    bool justEnteredSettingsViewDoNotOpenOscLayoutTool;
    uint16_t oscLayoutFingers;
    CustomEdgeSlideGestureRecognizer *slideToCloseSettingsViewRecognizer;
    UIStackView *parentStack;
    NSMutableDictionary *_settingStackDict;
    NSMutableArray *_favoriteSettingStackIdentifiers;
    bool settingStackWillBeRelocatedToLowestPosition;
    uint8_t currentSettingsMenuMode;
    UIView *snapshot;
    UIStackView* capturedStack;
    CADisplayLink *_autoScrollDisplayLink;
    CGFloat _scrollSpeed;
    CGFloat _currentRefreshRate;
}

@dynamic overrideUserInterfaceStyle;


//static NSString* bitrateFormat;
static const int bitrateTable[] = {
    500,
    1000,
    1500,
    2000,
    2500,
    3000,
    4000,
    5000,
    6000,
    7000,
    8000,
    9000,
    10000,
    11000,
    12000,
    13000,
    14000,
    15000,
    16000,
    17000,
    18000,
    19000,
    20000,
    21000,
    22000,
    23000,
    24000,
    25000,
    26000,
    27000,
    28000,
    29000,
    30000,
    31000,
    32000,
    33000,
    34000,
    35000,
    36000,
    37000,
    38000,
    39000,
    40000,
    41000,
    42000,
    43000,
    44000,
    45000,
    46000,
    47000,
    48000,
    49000,
    50000,
    50000,
    51000,
    52000,
    53000,
    54000,
    55000,
    56000,
    57000,
    58000,
    59000,
    60000,
    61000,
    62000,
    63000,
    64000,
    65000,
    66000,
    67000,
    68000,
    69000,
    70000,
    80000,
    90000,
    100000,
    110000,
    120000,
    130000,
    140000,
    150000,
    160000,
    170000,
    180000,
    200000,
    220000,
    240000,
    260000,
    280000,
    300000,
    320000,
    340000,
    360000,
    380000,
    400000,
    420000,
    440000,
    460000,
    480000,
    500000,
};

const int RESOLUTION_TABLE_SIZE = 7;
const int RESOLUTION_TABLE_CUSTOM_INDEX = RESOLUTION_TABLE_SIZE - 1;
CGSize resolutionTable[RESOLUTION_TABLE_SIZE];

-(int)getSliderValueForBitrate:(NSInteger)bitrate {
    int i;
    
    for (i = 0; i < (sizeof(bitrateTable) / sizeof(*bitrateTable)); i++) {
        if (bitrate <= bitrateTable[i]) {
            return i;
        }
    }
    
    // Return the last entry in the table
    return i - 1;
}

// This view is rooted at a ScrollView. To make it scrollable,
// we'll update content size here.
-(void)viewDidLayoutSubviews {
    CGFloat highestViewY = 0;
    
    // Enumerate the scroll view's subviews looking for the
    // highest view Y value to set our scroll view's content
    // size.
    
    for (UIView* view in self.scrollView.subviews) {
        // UIScrollViews have 2 default child views
        // which represent the horizontal and vertical scrolling
        // indicators. Ignore any views we don't recognize.
        if (![view isKindOfClass:[UILabel class]] &&
            ![view isKindOfClass:[UISegmentedControl class]] &&
            ![view isKindOfClass:[UISlider class]]) {
            continue;
        }
        
        CGFloat currentViewY = view.frame.origin.y + view.frame.size.height;
        if (currentViewY > highestViewY) {
            highestViewY = currentViewY;
        }
    }
    
    // Add a bit of padding so the view doesn't end right at the button of the display
    self.scrollView.contentSize = CGSizeMake(self.scrollView.contentSize.width,
                                             [self isIPhone] ? highestViewY + 20 : parentStack.frame.size.height + [self getStandardNavBarHeight] + 20);
    /*
    self.scrollView.translatesAutoresizingMaskIntoConstraints = NO;
    [NSLayoutConstraint activateConstraints:@[
        // [self.scrollView.topAnchor constraintEqualToAnchor:],
        [self.scrollView.leadingAnchor constraintEqualToAnchor:self.view.leadingAnchor],
        [self.scrollView.trailingAnchor constraintEqualToAnchor:self.view.trailingAnchor],
        [self.scrollView.topAnchor constraintEqualToAnchor:self.view.topAnchor],
        [self.scrollView.bottomAnchor constraintEqualToAnchor:self.view.bottomAnchor],
    ]];
    
    NSLog(@"settingsViewWidth: %f", self.view.bounds.size.width);
*/
    
    
    
    double delayInSeconds = 3;
    // Convert the delay into a dispatch_time_t value
    dispatch_time_t delayTime = dispatch_time(DISPATCH_TIME_NOW, (int64_t)(delayInSeconds * NSEC_PER_SEC));
    // Perform some task after the delay
    dispatch_after(delayTime, dispatch_get_main_queue(), ^{// Code to execute after the delay
        // [self updateResolutionAccordingly];
    });
    
}

// Adjust the subviews for the safe area on the iPhone X.
- (void)viewSafeAreaInsetsDidChange {
    [super viewSafeAreaInsetsDidChange];
    
    //if (@available(iOS 11.0, *)) {
    if (false) { // cancel this for portrait mode
        for (UIView* view in self.view.subviews) {
            // HACK: The official safe area is much too large for our purposes
            // so we'll just use the presence of any safe area to indicate we should
            // pad by 20.
            if (self.view.safeAreaInsets.left >= 20 || self.view.safeAreaInsets.right >= 20) {
                view.frame = CGRectMake(view.frame.origin.x + 20, view.frame.origin.y, view.frame.size.width, view.frame.size.height);
            }
        }
    }
}

BOOL isCustomResolution(CGSize res) {
    if (res.width == 0 && res.height == 0) {
        return NO;
    }
    
    for (int i = 0; i < RESOLUTION_TABLE_CUSTOM_INDEX; i++) {
        
        if ((res.width == resolutionTable[i].width && res.height == resolutionTable[i].height) || (res.height == resolutionTable[i].width && res.width == resolutionTable[i].height)) {
            return NO;
        }
    }
    
    return YES;
}

+ (bool)isLandscapeNow {
    return CGRectGetWidth([[UIScreen mainScreen]bounds]) > CGRectGetHeight([[UIScreen mainScreen]bounds]);
}

- (bool)isFullScreenRequired {
    NSDictionary *infoDictionary = [[NSBundle mainBundle] infoDictionary];
    NSNumber *requiresFullScreen = infoDictionary[@"UIRequiresFullScreen"];
    
    if (requiresFullScreen != nil) {
        return [requiresFullScreen boolValue];
    }
    // Default behavior if the key is not set
    return true;
}

- (bool)isAirPlayEnabled{
    return [self.externalDisplayModeSelector selectedSegmentIndex] == 1;
}

- (void)updateResolutionTable{
    UIWindow *window = UIApplication.sharedApplication.windows.firstObject;
    CGFloat screenScale = window.screen.scale;
    CGFloat safeAreaWidth = (window.frame.size.width - window.safeAreaInsets.left - window.safeAreaInsets.right) * screenScale;
    CGFloat appWindowWidth = window.frame.size.width * screenScale;
    CGFloat appWindowHeight = window.frame.size.height * screenScale;
    if([self isAirPlayEnabled] && UIScreen.screens.count > 1){
        CGRect bounds = [UIScreen.screens.lastObject bounds];
        screenScale = [UIScreen.screens.lastObject scale];
        appWindowWidth = bounds.size.width * screenScale;
        appWindowHeight = bounds.size.height * screenScale;
    }
    bool needSwapWidthAndHeight = appWindowWidth > appWindowHeight;
    
    resolutionTable[4] = CGSizeMake(safeAreaWidth, appWindowHeight);

    for(uint8_t i=0;i<7;i++){
        CGFloat longSideLen = resolutionTable[i].height > resolutionTable[i].width ? resolutionTable[i].height : resolutionTable[i].width;
        CGFloat shortSideLen = resolutionTable[i].height < resolutionTable[i].width ? resolutionTable[i].height : resolutionTable[i].width;
        if(needSwapWidthAndHeight) resolutionTable[i] = CGSizeMake(longSideLen, shortSideLen);
        else resolutionTable[i] = CGSizeMake(shortSideLen, longSideLen);
    }

    resolutionTable[5] = CGSizeMake(appWindowWidth, appWindowHeight);

    [self updateResolutionDisplayViewText];
}

// this will also be called back when device orientation changes
- (void)viewWillTransitionToSize:(CGSize)size withTransitionCoordinator:(id<UIViewControllerTransitionCoordinator>)coordinator {
    [super viewWillTransitionToSize:size withTransitionCoordinator:coordinator];
    double delayInSeconds = 0.2;
    // Convert the delay into a dispatch_time_t value
    dispatch_time_t delayTime = dispatch_time(DISPATCH_TIME_NOW, (int64_t)(delayInSeconds * NSEC_PER_SEC));
    // Perform some task after the delay
    dispatch_after(delayTime, dispatch_get_main_queue(), ^{// Code to execute after the delay
        [self updateResolutionTable];
    });
}

- (void)viewDidAppear:(BOOL)animated{
    [super viewDidAppear:NO];
    [self updateResolutionTable];
    //[self updateTheme];
    NSLog(@"Resolution table updated");
}


- (void)deviceOrientationDidChange{
    double delayInSeconds = 1.0;
    // Convert the delay into a dispatch_time_t value
    dispatch_time_t delayTime = dispatch_time(DISPATCH_TIME_NOW, (int64_t)(delayInSeconds * NSEC_PER_SEC));
    // Perform some task after the delay
    dispatch_after(delayTime, dispatch_get_main_queue(), ^{
        // Code to execute after the delay
        // [self updateResolutionTable];
        // since we have viewWillTransitionToSize being called back both when orientation changed & app window size changed, resoltion update is dprecated here
    });
}

- (void)viewDidDisappear:(BOOL)animated{
    [super viewDidDisappear:NO];
    [[NSNotificationCenter defaultCenter] postNotificationName:@"SettingsViewClosedNotification" object:self]; // notify other view that settings view just closed
}

/*
- (void)addExitButtonOnTop{
    UIButton *exitButton = [UIButton buttonWithType:UIButtonTypeSystem];
    [exitButton setTitle:@"Exit" forState:UIControlStateNormal];
    [exitButton setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal]; // Set font color
    exitButton.backgroundColor = [UIColor clearColor]; // Set background color
    exitButton.titleLabel.font = [UIFont boldSystemFontOfSize:16.0]; // Set font size and style
    exitButton.layer.cornerRadius = 8.0; // Optional: Round corners if desired
    exitButton.clipsToBounds = YES; // Ensure rounded corners are applied properly
    [exitButton addTarget:self action:@selector(exitButtonTapped) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:exitButton];
    exitButton.frame = CGRectMake(0, 20, 200, 50); // Adjust Y and height as needed
}*/

- (SettingsMenuMode)getSettingsMenuMode{
    return currentSettingsMenuMode;
}

- (void)edgeSwiped {
    [self.mainFrameViewController closeSettingViewAnimated:YES];
}

- (BOOL)isIPhone {
    return [UIDevice currentDevice].userInterfaceIdiom == UIUserInterfaceIdiomPhone;
}

- (CGFloat)getStandardNavBarHeight{
    return [self isIPhone] ? UINavigationBarHeightIPhone : UINavigationBarHeightIPad;
}


- (void)initParentStack{
    self.scrollView.contentInsetAdjustmentBehavior = UIScrollViewContentInsetAdjustmentAutomatic;
    // 可选：确保 scrollView 开启垂直滚动
    self.scrollView.alwaysBounceVertical = YES;
    self.scrollView.showsVerticalScrollIndicator = NO;

    /*
    self.scrollView.translatesAutoresizingMaskIntoConstraints = NO;
    [NSLayoutConstraint activateConstraints:@[
        // [self.scrollView.topAnchor constraintEqualToAnchor:],
        [self.scrollView.leadingAnchor constraintEqualToAnchor:self.view.leadingAnchor],
        [self.scrollView.trailingAnchor constraintEqualToAnchor:self.view.trailingAnchor],
        [self.scrollView.topAnchor constraintEqualToAnchor:self.view.topAnchor],
        [self.scrollView.bottomAnchor constraintEqualToAnchor:self.view.bottomAnchor],
    ]];
     */

    parentStack = [[UIStackView alloc] init];
    parentStack.axis = UILayoutConstraintAxisVertical;
    parentStack.spacing = 0;
    parentStack.translatesAutoresizingMaskIntoConstraints = NO;
    [self.scrollView addSubview:parentStack];
    [NSLayoutConstraint activateConstraints:@[
        [parentStack.topAnchor constraintEqualToAnchor:self.scrollView.contentLayoutGuide.topAnchor constant: [self getStandardNavBarHeight]],
        [parentStack.bottomAnchor constraintEqualToAnchor:self.scrollView.contentLayoutGuide.bottomAnchor constant:-20],
        [parentStack.centerXAnchor constraintEqualToAnchor:self.view.centerXAnchor constant: 0], //mark: settingMenuLayout
        [parentStack.widthAnchor constraintEqualToAnchor:self.view.widthAnchor constant:-20] // section width adjusted here //mark: settingMenuLayout
    ]];
}

- (void)addSetting:(UIStackView *)stack ofId:(NSString* )identifier withInfoTag:(BOOL)attched to:(MenuSectionView* )menuSection{
    stack.accessibilityIdentifier = identifier;
    [_settingStackDict setObject:stack forKey:identifier];
    if(attched) [self attachInfoTagForStack:stack];
    [menuSection addSubStackView:stack];
}
    
- (void)layoutSections{
    MenuSectionView *videoSection = [[MenuSectionView alloc] init];
    videoSection.sectionTitle = [LocalizationHelper localizedStringForKey:@"Video"];
    if (@available(iOS 13.0, *)) {
        [videoSection setSectionIcon:[UIImage systemImageNamed:@"airplayvideo"]];
    } else [videoSection setSectionIcon:nil];
    
    [self addSetting:self.resolutionStack ofId:@"resolutionStack" withInfoTag:YES to:videoSection];
    [self addSetting:self.fpsStack ofId:@"fpsStack" withInfoTag:NO to:videoSection];
    [self addSetting:self.codecStack ofId:@"codecStack" withInfoTag:NO to:videoSection];
    [videoSection addToParentStack:parentStack];
    [videoSection setExpanded:YES];
    //_fpsStack.userInteractionEnabled = NO;
    
    MenuSectionView *gesturesSection = [[MenuSectionView alloc] init];
    gesturesSection.sectionTitle = [LocalizationHelper localizedStringForKey:@"Gestures"];
    if (@available(iOS 13.0, *)) {
        [gesturesSection setSectionIcon:[UIImage systemImageNamed:@"hand.draw"]];
    } else [gesturesSection setSectionIcon:nil];
    
    [self addSetting:self.keyboardToggleFingerNumStack ofId:@"keyboardToggleFingerNumStack" withInfoTag:NO to:gesturesSection];
    [self addSetting:self.slideToSettingsScreenEdgeStack ofId:@"slideToSettingsScreenEdgeStack" withInfoTag:NO to:gesturesSection];
    [self addSetting:self.slideToCmdToolScreenEdgeStack ofId:@"slideToCmdToolScreenEdgeStack" withInfoTag:NO to:gesturesSection];
    [self addSetting:self.slideToSettingsDistanceStack ofId:@"slideToSettingsDistanceStack" withInfoTag:NO to:gesturesSection];

    [self addSetting:self.audioOnPcStack ofId:@"audioOnPcStack" withInfoTag:NO to:gesturesSection];
    // [self addSetting:self.codecStack ofIdentifier:@"codecStack" to:gesturesSection];
    [self addSetting:self.yuv444Stack ofId:@"yuv444Stack" withInfoTag:NO to:gesturesSection];
    [self addSetting:self.HdrStack ofId:@"HdrStack" withInfoTag:NO to:gesturesSection];
    [self addSetting:self.optimizeSettingsStack ofId:@"optimizeSettingsStack" withInfoTag:NO to:gesturesSection];
    [self addSetting:self.multiControllerStack ofId:@"multiControllerStack" withInfoTag:NO to:gesturesSection];
    [self addSetting:self.optimizeSettingsStack ofId:@"optimizeSettingsStack" withInfoTag:NO to:gesturesSection];
    [self addSetting:self.liftStreamViewForKeyboardStack ofId:@"liftStreamViewForKeyboardStack" withInfoTag:NO to:gesturesSection];
    [self addSetting:self.framepacingStack ofId:@"framepacingStack" withInfoTag:NO to:gesturesSection];
    [self addSetting:self.reverseMouseWheelDirectionStack ofId:@"reverseMouseWheelDirectionStack" withInfoTag:NO to:gesturesSection];
    [self addSetting:self.statsOverlayStack ofId:@"statsOverlayStack" withInfoTag:NO to:gesturesSection];
    [self addSetting:self.externalDisplayModeStack ofId:@"externalDisplayModeStack" withInfoTag:NO to:gesturesSection];
    [self addSetting:self.localMousePointerModeStack ofId:@"localMousePointerModeStack" withInfoTag:NO to:gesturesSection];
    [self addSetting:self.onScreenWidgetStack ofId:@"onScreenWidgetStack" withInfoTag:NO to:gesturesSection];

        
    [gesturesSection addToParentStack:parentStack];
    [gesturesSection setExpanded:YES];
}


- (void)layoutWidgetes {
    
    // [self.view addSubview:self.navigationBar];
    
    self.scrollView.contentInsetAdjustmentBehavior = UIScrollViewContentInsetAdjustmentAutomatic;
    
    // 可选：确保 scrollView 开启垂直滚动
    self.scrollView.alwaysBounceVertical = YES;
    
    UIStackView* parentStackTmp = [[UIStackView alloc] init];
    parentStackTmp.axis = UILayoutConstraintAxisVertical;
    parentStackTmp.spacing = 13;
    parentStackTmp.translatesAutoresizingMaskIntoConstraints = NO;
    [self.scrollView addSubview:parentStackTmp];
    [NSLayoutConstraint activateConstraints:@[
        [parentStackTmp.topAnchor constraintEqualToAnchor:self.scrollView.contentLayoutGuide.topAnchor constant: [self getStandardNavBarHeight] + 300],
        [parentStackTmp.bottomAnchor constraintEqualToAnchor:self.scrollView.contentLayoutGuide.bottomAnchor constant:-20],
        [parentStackTmp.leadingAnchor constraintEqualToAnchor:self.scrollView.contentLayoutGuide.leadingAnchor constant: 14],
        [parentStackTmp.trailingAnchor constraintEqualToAnchor:self.scrollView.contentLayoutGuide.trailingAnchor constant: -15],
        [parentStackTmp.widthAnchor constraintEqualToAnchor:self.scrollView.contentLayoutGuide.widthAnchor]
    ]];
    
    
    [parentStackTmp addArrangedSubview:self.resolutionStack];
    // self.resolutionStack.hidden = YES;
    [parentStackTmp addArrangedSubview:self.fpsStack];
    // self.fpsStack.hidden = YES;
    [parentStackTmp addArrangedSubview:self.bitrateStack];
    // self.bitrateStack.hidden = YES;
    [parentStackTmp addArrangedSubview:self.touchModeStack];
    [parentStackTmp addArrangedSubview:self.asyncTouchStack];
    [parentStackTmp addArrangedSubview:self.pointerVelocityDividerStack];
    [parentStackTmp addArrangedSubview:self.pointerVelocityFactorStack];
    [parentStackTmp addArrangedSubview:self.touchMoveEventIntervalStack];
    [parentStackTmp addArrangedSubview:self.mousePointerVelocityStack];
    [parentStackTmp addArrangedSubview:self.onScreenWidgetStack];
    [parentStackTmp addArrangedSubview:self.keyboardToggleFingerNumStack];
    [parentStackTmp addArrangedSubview:self.liftStreamViewForKeyboardStack];
    [parentStackTmp addArrangedSubview:self.showKeyboardToolbarStack];
    [parentStackTmp addArrangedSubview:self.slideToSettingsScreenEdgeStack];
    [parentStackTmp addArrangedSubview:self.slideToCmdToolScreenEdgeStack];
    [parentStackTmp addArrangedSubview:self.slideToSettingsDistanceStack];
    [parentStackTmp addArrangedSubview:self.optimizeSettingsStack];
    [parentStackTmp addArrangedSubview:self.multiControllerStack];
    [parentStackTmp addArrangedSubview:self.swapAbaxyStack];
    [parentStackTmp addArrangedSubview:self.audioOnPcStack];
    [parentStackTmp addArrangedSubview:self.codecStack];
    [parentStackTmp addArrangedSubview:self.yuv444Stack];
    [parentStackTmp addArrangedSubview:self.HdrStack];
    [parentStackTmp addArrangedSubview:self.framepacingStack];
    [parentStackTmp addArrangedSubview:self.reverseMouseWheelDirectionStack];
    [parentStackTmp addArrangedSubview:self.citrixX1MouseStack];
    [parentStackTmp addArrangedSubview:self.statsOverlayStack];
    [parentStackTmp addArrangedSubview:self.unlockDisplayOrientationStack];
    [parentStackTmp addArrangedSubview:self.externalDisplayModeStack];
    [parentStackTmp addArrangedSubview:self.localMousePointerModeStack];
    [parentStackTmp removeFromSuperview];
}

- (void)handleAutoScroll:(CGPoint)location{
    bool scrollDown = location.y > self.view.bounds.size.height - 100;
    bool scrollUp = location.y < 150;
    
    NSLog(@"%f flag: %d, %d, obj: %@, locY: %f", CACurrentMediaTime(), scrollUp, scrollDown, _autoScrollDisplayLink, location.y);
    
    if(!(scrollUp||scrollDown)) [self stopAutoScroll];
    
    if((scrollUp||scrollDown) && _autoScrollDisplayLink == nil ){
    
    // NSLog(@"_autoScrollDisplayLink: %@", _autoScrollDisplayLink);
    //if (!_autoScrollDisplayLink) {
        //[_autoScrollDisplayLink ]
        _scrollSpeed = fabs(120/_currentRefreshRate);
        // _scrollSpeed = 2;
        CGFloat scrollDirection = 0;
        if(scrollDown) scrollDirection = 1;
        if(scrollUp) scrollDirection = -1;
        _scrollSpeed = _scrollSpeed * scrollDirection;
        NSLog(@"%f, scrollSpeed: %f", CACurrentMediaTime(), _scrollSpeed);

        _autoScrollDisplayLink = [CADisplayLink displayLinkWithTarget:self selector:@selector(startScroll)];
        [_autoScrollDisplayLink addToRunLoop:[NSRunLoop mainRunLoop] forMode:NSRunLoopCommonModes];
    }

    //}
}

- (void)stopAutoScroll {
    [_autoScrollDisplayLink invalidate];
    _autoScrollDisplayLink = nil;
}

- (BOOL)scrolledToTop {
    return self.scrollView.contentOffset.y <= 0;
}

- (BOOL)scrolledToBottom {
    CGFloat maxOffsetY = self.scrollView.contentSize.height - self.scrollView.bounds.size.height;
    return self.scrollView.contentOffset.y >= maxOffsetY;
}


- (void)startScroll {
    
    if(![self scrolledToTop] && ![self scrolledToBottom]){
        CGPoint snapshotLocation = snapshot.center;
        snapshotLocation = CGPointMake(snapshotLocation.x, snapshotLocation.y+_scrollSpeed);
        snapshot.center = snapshotLocation;
    }
    
    CGPoint offset = self.scrollView.contentOffset;
    CGFloat newY = offset.y + _scrollSpeed;
    
    // 限制滚动范围
    newY = MAX(0, MIN(newY, self.scrollView.contentSize.height - self.scrollView.bounds.size.height));

    [self.scrollView setContentOffset:CGPointMake(offset.x, newY) animated:NO];
}

- (void)estimateFPSWithCompletion:(void (^)(CGFloat fps))completion {
    CADisplayLink *link = [CADisplayLink displayLinkWithTarget:self selector:@selector(handleTick:)];

    // 让系统决定刷新率
    link.preferredFramesPerSecond = 0;

    // 关联block和时间戳
    objc_setAssociatedObject(link, @"fpsCompletion", completion, OBJC_ASSOCIATION_COPY_NONATOMIC);
    objc_setAssociatedObject(link, @"lastTimestamp", @(0), OBJC_ASSOCIATION_RETAIN_NONATOMIC);

    [link addToRunLoop:[NSRunLoop mainRunLoop] forMode:NSRunLoopCommonModes];
}

- (void)handleTick:(CADisplayLink *)link {
    NSTimeInterval lastTimestamp = [objc_getAssociatedObject(link, @"lastTimestamp") doubleValue];
    void (^completion)(CGFloat fps) = objc_getAssociatedObject(link, @"fpsCompletion");

    if (lastTimestamp > 0) {
        NSTimeInterval delta = link.timestamp - lastTimestamp;
        CGFloat fps = 1.0 / delta;

        // 先停止CADisplayLink，避免继续调用
        [link invalidate];
        link = nil;

        if (completion) {
            completion(fps);
        }

        // 清理关联，防止内存泄漏
        objc_setAssociatedObject(link, @"fpsCompletion", nil, OBJC_ASSOCIATION_COPY_NONATOMIC);
        objc_setAssociatedObject(link, @"lastTimestamp", nil, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    } else {
        objc_setAssociatedObject(link, @"lastTimestamp", @(link.timestamp), OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    }
}




- (NSInteger)parentStackIndexForLocation:(CGPoint)location {
    for (NSInteger i = parentStack.arrangedSubviews.count-1; i >=0; i--) {
        UIView *subview = parentStack.arrangedSubviews[i];
        // CGRect frame = [subview convertRect:subview.bounds toView:parentStack];
        CGFloat stackMinY = CGRectGetMinY(subview.frame);
        NSLog(@" index: %ld, stackY: %f, touchY: %f", (long)i, CGRectGetMidY(subview.frame), location.y);
        if(stackMinY < location.y){
            NSLog(@"index: %ld", i);
            //subview.backgroundColor = [ThemeManager appPrimaryColorWithAlpha];
            return i;
        }
    }
    return 0;
}

- (void)updateRelocationIndicator:(CGPoint)locationInParentStack{
    uint16_t currentIndex = [self parentStackIndexForLocation:locationInParentStack];
    UIStackView* currentStack;
    for (NSInteger i = parentStack.arrangedSubviews.count-1; i >=0; i--) {
        currentStack = parentStack.arrangedSubviews[i];

        if(currentIndex == i){
            settingStackWillBeRelocatedToLowestPosition = false;
            if(i == parentStack.arrangedSubviews.count-1 && locationInParentStack.y > CGRectGetMaxY(currentStack.frame)){
                snapshot.layer.cornerRadius = 6;
                snapshot.layer.masksToBounds = YES;
                snapshot.clipsToBounds = YES;
                snapshot.backgroundColor = [UIColor colorWithRed:0.5 green:0.5 blue:1 alpha:0.35];
                currentStack.backgroundColor = [UIColor clearColor];
                settingStackWillBeRelocatedToLowestPosition = true;
            }
            else{
                currentStack.layer.cornerRadius = 6;
                currentStack.layer.masksToBounds = YES;
                currentStack.clipsToBounds = YES;
                currentStack.backgroundColor = [ThemeManager appPrimaryColorWithAlpha];
                snapshot.backgroundColor = [UIColor clearColor];
            }
        }
        else{
            currentStack.layer.cornerRadius = 0;
            currentStack.backgroundColor = [UIColor clearColor];
        }
    }
}

- (void)clearRelocationIndicator{
    for (UIView* view in parentStack.arrangedSubviews) {
        view.layer.cornerRadius = 0;
        view.backgroundColor = [UIColor clearColor];
    }
}

- (void)findCapturedStackByTouchLocation:(CGPoint)point{
    UIView *touchedView = [parentStack hitTest:point withEvent:nil];
    if([touchedView isKindOfClass:[UIStackView class]]){
        if(touchedView.accessibilityIdentifier != nil) capturedStack = (UIStackView *)touchedView;
    }
    else if([touchedView.superview isKindOfClass:[UIStackView class]] && touchedView.superview.accessibilityIdentifier != nil) capturedStack = (UIStackView *)touchedView.superview;
    else NSLog(@"hit test: not setting stack captured");
}

- (UIAlertController* )prepareAddToFavoriteActionSheet{
    // actionsheet
    UIAlertController *actionSheet = [UIAlertController alertControllerWithTitle:nil
                                                                         message:nil
                                                                  preferredStyle:UIAlertControllerStyleActionSheet];
    UIAlertAction *addFavoriteAction = [UIAlertAction actionWithTitle:[LocalizationHelper localizedStringForKey:@"Add to favorite"]
                                                                style:UIAlertActionStyleDefault
                                                              handler:^(UIAlertAction * _Nonnull action) {
        [self addSettingToFavorite:self->capturedStack];
        // 在这里执行收藏逻辑
    }];
    [actionSheet addAction:addFavoriteAction];
    return actionSheet;
}

- (void)handleLongPress:(UILongPressGestureRecognizer *)gesture {
    CGPoint locationInParentStack = [gesture locationInView:parentStack];
    CGPoint locationInRootView = [gesture locationInView:self.view.superview];
    if(currentSettingsMenuMode == AllSettings){
        if (gesture.state == UIGestureRecognizerStateBegan) {
            [self findCapturedStackByTouchLocation:locationInParentStack];
            if(capturedStack == nil) return;
            UIAlertController* actionSheet = [self prepareAddToFavoriteActionSheet];
            actionSheet.popoverPresentationController.sourceView = capturedStack;
            [self presentViewController:actionSheet animated:YES completion:nil];
        }
    }
    
    static CGPoint originalCenter;
    static NSInteger originalIndex;
    if(gesture.state == UIGestureRecognizerStateBegan){
        
        [self estimateFPSWithCompletion:^(CGFloat fps) {
            self->_currentRefreshRate = fps;
        }];
        _autoScrollDisplayLink = nil;
    }

    if(currentSettingsMenuMode == FavoriteSettings){
        switch (gesture.state) {
            case UIGestureRecognizerStateBegan:
                // 创建快照视图
                [self findCapturedStackByTouchLocation:locationInParentStack];
                if(capturedStack == nil) return;

                snapshot = [capturedStack snapshotViewAfterScreenUpdates:YES];
                snapshot.center = capturedStack.center;
                [parentStack addSubview:snapshot];
                capturedStack.hidden = YES;
                originalCenter = capturedStack.center;
                originalIndex = [parentStack.arrangedSubviews indexOfObject:capturedStack];
                break;
                
            case UIGestureRecognizerStateChanged:
                snapshot.center = CGPointMake(locationInParentStack.x, locationInParentStack.y);
                NSLog(@"coordY in rootView: %f", locationInRootView.y);
                [self handleAutoScroll:locationInRootView];
                [self updateRelocationIndicator:locationInParentStack];
                
                
                break;
            case UIGestureRecognizerStateCancelled:
            case UIGestureRecognizerStateEnded:
                // 更新快照视图位置
                // snapshot.center = CGPointMake(originalCenter.x, point.y);
                [self stopAutoScroll];
                [snapshot removeFromSuperview];
                snapshot = nil;
                // 计算新的插入位置
                NSInteger newIndex = [self parentStackIndexForLocation:locationInParentStack];
                [self clearRelocationIndicator];
                NSInteger oldIndex = [parentStack.arrangedSubviews indexOfObject:capturedStack];
                newIndex = newIndex > oldIndex ? newIndex - 1 : newIndex;
                //NSInteger newIndex = 1;
                //NSLog(@"newidx %ld, oldidx %ld", newIndex, oldIndex);
                if(settingStackWillBeRelocatedToLowestPosition){
                    newIndex = newIndex + 1;
                    settingStackWillBeRelocatedToLowestPosition = false;
                }
                
                if (newIndex != NSNotFound) {
                    if(newIndex >= parentStack.arrangedSubviews.count) newIndex = parentStack.arrangedSubviews.count-1;
                    [parentStack removeArrangedSubview:capturedStack];
                    [parentStack insertArrangedSubview:capturedStack atIndex:newIndex];
                    // [parentStack addSubview:capturedStack];
                    originalIndex = newIndex;
                    capturedStack.hidden = NO;
                    [self saveFavoriteSettingStackIdentifiers];
                }
                // 移除快照视图，显示原始视图
                break;
                
            default:break;
        }
    }
}
    

- (void)addSettingToFavorite:(UIStackView* )settingStack{
    [_favoriteSettingStackIdentifiers addObject:settingStack.accessibilityIdentifier];
    for(NSString *identifier in _favoriteSettingStackIdentifiers){
        NSLog(@"favorite setting: %@", identifier);
    }
    [self saveFavoriteSettingStackIdentifiers];
}

- (void)attachRemoveButtonForStack:(UIStackView* )stack{
    UIButton* button = [UIButton buttonWithType:UIButtonTypeSystem];
    if (@available(iOS 13.0, *)) {
        UIImageSymbolConfiguration *config = [UIImageSymbolConfiguration configurationWithPointSize:16 weight:UIImageSymbolWeightMedium];
        [button setImage:[UIImage systemImageNamed:@"minus.circle" withConfiguration:config] forState:UIControlStateNormal];
    } else {
        [button setTitle:@"Remove" forState:UIControlStateNormal];
    }
    button.accessibilityIdentifier = @"removeButton";
    button.translatesAutoresizingMaskIntoConstraints = NO;
    button.tintColor = [UIColor redColor];
    
    [button addTarget:self action:@selector(removeSettingStackFromFavorites:) forControlEvents:UIControlEventTouchUpInside];
    
    [stack addSubview:button];
    [NSLayoutConstraint activateConstraints:@[
        [button.trailingAnchor constraintEqualToAnchor:stack.trailingAnchor constant:-8],
        [button.topAnchor constraintEqualToAnchor:stack.topAnchor],
    ]];
}

- (void)attachInfoTagForStack:(UIStackView* )stack{
    bool usingTextButton = false;
    UIButton* button = [UIButton buttonWithType:UIButtonTypeSystem];
    if (@available(iOS 13.0, *)) {
        UIImageSymbolConfiguration *config = [UIImageSymbolConfiguration configurationWithPointSize:13.5 weight:UIImageSymbolWeightBold];
        [button setImage:[UIImage systemImageNamed:@"info.circle" withConfiguration:config] forState:UIControlStateNormal];
    } else {
        usingTextButton = true;
        [button setTitle:@"info" forState:UIControlStateNormal];
        button.titleLabel.font = [UIFont systemFontOfSize:13 weight:UIFontWeightBold];
    }
    button.accessibilityIdentifier = @"infoButton";
    button.translatesAutoresizingMaskIntoConstraints = NO;
    button.tintColor = [ThemeManager appPrimaryColor];
    
    [button addTarget:self action:@selector(infoButtonTapped:) forControlEvents:UIControlEventTouchUpInside];
    
    [stack addSubview:button];
    [NSLayoutConstraint activateConstraints:@[
        [button.trailingAnchor constraintEqualToAnchor:stack.trailingAnchor constant:-4],
        [button.topAnchor constraintEqualToAnchor:stack.topAnchor constant: usingTextButton ? -2 : 0],
    ]];
}

-  (void)infoButtonTapped:(UIButton* )sender{
    
    NSString* tipText = [NSString stringWithFormat:@"dummy text for setting stack: %@", sender.superview.accessibilityIdentifier];
    
    UIAlertController *tipsAlertController = [UIAlertController alertControllerWithTitle: [LocalizationHelper localizedStringForKey:@"Tips"] message: [LocalizationHelper localizedStringForKey:@"%@", tipText] preferredStyle:UIAlertControllerStyleAlert];

    UIAlertAction *readInstruction = [UIAlertAction actionWithTitle:[LocalizationHelper localizedStringForKey:@"Online Documentation"]
                                                           style:UIAlertActionStyleDefault
                                                         handler:^(UIAlertAction *action){
        NSURL *url = [NSURL URLWithString:@"https://b23.tv/J8qEXOr"];
        if ([[UIApplication sharedApplication] canOpenURL:url]) {
            [[UIApplication sharedApplication] openURL:url options:@{} completionHandler:nil];
        }
    }];
    
    UIAlertAction *okAction = [UIAlertAction actionWithTitle:[LocalizationHelper localizedStringForKey:@"OK"]
                                                           style:UIAlertActionStyleDefault
                                                     handler:nil];
    [tipsAlertController addAction:readInstruction];
    [tipsAlertController addAction:okAction];
    [self presentViewController:tipsAlertController animated:YES completion:nil];
}



- (void)removeSettingStackFromFavorites:(UIButton* )sender{
    [sender.superview removeFromSuperview];
    [sender removeFromSuperview];
    [self saveFavoriteSettingStackIdentifiers];
}

- (void)layoutSettingsView{
    [self.view layoutSubviews];
    if(currentSettingsMenuMode == AllSettings){
        for(MenuSectionView* section in parentStack.arrangedSubviews) [section updateViewForFoldState];
    }
}

- (void)switchToFavoriteSettings{
    [self updateTheme];
    currentSettingsMenuMode = FavoriteSettings;
    DataManager* dataMan = [[DataManager alloc] init];
    Settings *currentSettings = [dataMan retrieveSettings];
    currentSettings.settingsMenuMode = [NSNumber numberWithInteger:currentSettingsMenuMode];
    [dataMan saveData];
    
    for(UIView* view in parentStack.subviews){
        [view removeFromSuperview];
    }
    parentStack.spacing = 15;
    [self loadFavoriteSettingStackIdentifiers];
    for(NSString* settingIdentifier in _favoriteSettingStackIdentifiers){
        [parentStack addArrangedSubview:_settingStackDict[settingIdentifier]];
    }
}

- (void)switchToAllSettings{

    
    for(UIView* view in parentStack.subviews){
        [view removeFromSuperview];
    }
    [self initParentStack];
    [self layoutSections];
    [self updateTheme];
        //[self doneRemoveSettingItem];
    currentSettingsMenuMode = AllSettings;
    DataManager* dataMan = [[DataManager alloc] init];
    Settings *currentSettings = [dataMan retrieveSettings];
    currentSettings.settingsMenuMode = [NSNumber numberWithInteger:currentSettingsMenuMode];
    [dataMan saveData];

}

- (void)enterRemoveSettingItemMode{
    currentSettingsMenuMode = RemoveSettingItem;
    for(UIStackView* stack in parentStack.arrangedSubviews){
        for(UIView* view in stack.subviews){
            if([view.accessibilityIdentifier isEqualToString:@"infoButton"]) view.hidden = YES;
            // view.userInteractionEnabled = false;
        }
        [self attachRemoveButtonForStack:stack];
        // stack.userInteractionEnabled = false;
    }
}

- (void)doneRemoveSettingItem{
    currentSettingsMenuMode = FavoriteSettings;
    for(UIStackView* stack in parentStack.arrangedSubviews){
        //stack.userInteractionEnabled = true;
        for(UIView* view in stack.subviews){
            //view.
            if([view.accessibilityIdentifier isEqualToString:@"infoButton"]) view.hidden = NO;
            if([view.accessibilityIdentifier isEqualToString:@"removeButton"]) [view removeFromSuperview];
        }
    }
}

- (void)saveFavoriteSettingStackIdentifiers {
    
    if(currentSettingsMenuMode == RemoveSettingItem){
        [_favoriteSettingStackIdentifiers removeAllObjects];
        for(NSInteger i = 0; i < parentStack.arrangedSubviews.count; i++){
            [_favoriteSettingStackIdentifiers addObject:parentStack.arrangedSubviews[i].accessibilityIdentifier];
        }
    }
    
    [[NSUserDefaults standardUserDefaults] setObject:_favoriteSettingStackIdentifiers forKey:@"FavoriteSettingStackIdentifiers"];
    [[NSUserDefaults standardUserDefaults] synchronize];
}

- (void)loadFavoriteSettingStackIdentifiers {
    NSArray *savedArray = [[NSUserDefaults standardUserDefaults] objectForKey:@"FavoriteSettingStackIdentifiers"];
    if ([savedArray isKindOfClass:[NSArray class]]) {
        _favoriteSettingStackIdentifiers = [savedArray mutableCopy];
    } else {
        _favoriteSettingStackIdentifiers = [NSMutableArray array];
    }
    /*
    for(NSString* str in _favoriteSettingStackIdentifiers){
        NSLog(@"favarite setting loaded: %@", str);
    }
     */
}

- (void)viewDidLoad {
    //[self updateTheme];
    [UIView performWithoutAnimation:^{
        
        settingStackWillBeRelocatedToLowestPosition = false;
        
        [[NSUserDefaults standardUserDefaults] setBool:NO forKey:@"_UIConstraintBasedLayoutLogUnsatisfiable"];
        
        UILongPressGestureRecognizer *longPress = [[UILongPressGestureRecognizer alloc] initWithTarget:self action:@selector(handleLongPress:)];
        [self.view addGestureRecognizer:longPress];
        
        _settingStackDict = [[NSMutableDictionary alloc] init];
        
        // return;
        BOOL isIPad = ([UIDevice currentDevice].userInterfaceIdiom == UIUserInterfaceIdiomPad);
        if(isIPad){
            //[self layoutWidgetes]; // layout for ipad tmply
            // [self.view ]
            for(UIView* view in self.view.subviews){
                [view removeFromSuperview];
            }
            [self initParentStack];
            [self layoutSections];
        }
        
        
        // [self swi];
        
        self->slideToCloseSettingsViewRecognizer = [[CustomEdgeSlideGestureRecognizer alloc] initWithTarget:self action:@selector(edgeSwiped)];
        slideToCloseSettingsViewRecognizer.edges = UIRectEdgeLeft;
        slideToCloseSettingsViewRecognizer.normalizedThresholdDistance = 0.0;
        slideToCloseSettingsViewRecognizer.EDGE_TOLERANCE = 10;
        slideToCloseSettingsViewRecognizer.immediateTriggering = true;
        slideToCloseSettingsViewRecognizer.delaysTouchesBegan = NO;
        slideToCloseSettingsViewRecognizer.delaysTouchesEnded = NO;
        [self.view addGestureRecognizer:slideToCloseSettingsViewRecognizer];
        
        justEnteredSettingsViewDoNotOpenOscLayoutTool = true;
        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(deviceOrientationDidChange) // handle orientation change since i made portrait mode available
                                                     name:UIDeviceOrientationDidChangeNotification
                                                   object:nil];
        
        // Always run settings in dark mode because we want the light fonts
        if (@available(iOS 13.0, tvOS 13.0, *)) {
            self.overrideUserInterfaceStyle = UIUserInterfaceStyleDark;
        }
        
        DataManager* dataMan = [[DataManager alloc] init];
        TemporarySettings* currentSettings = [dataMan getSettings];
        
        currentSettingsMenuMode = currentSettings.settingsMenuMode.intValue;
        [self loadFavoriteSettingStackIdentifiers];
        if(currentSettings.settingsMenuMode.intValue == FavoriteSettings) [self switchToFavoriteSettings];
        /*
        switch (currentSettingsMenuMode) {
            case FavoriteSettings:
                [self switchToFavoriteSettings];
                break;
            case AllSettings:
                //[self switchToAllSettings];
                break;
            default:
                break;
        }
        */
        
        
        // Ensure we pick a bitrate that falls exactly onto a slider notch
        _bitrate = bitrateTable[[self getSliderValueForBitrate:[currentSettings.bitrate intValue]]];
        
        // Get the size of the screen with and without safe area insets
        UIWindow *window = UIApplication.sharedApplication.windows.firstObject;
        CGFloat screenScale = window.screen.scale;
        CGFloat safeAreaWidth = (window.frame.size.width - window.safeAreaInsets.left - window.safeAreaInsets.right) * screenScale;
        CGFloat fullScreenWidth = window.frame.size.width * screenScale;
        CGFloat fullScreenHeight = window.frame.size.height * screenScale;
        
        self.resolutionDisplayView.layer.cornerRadius = 10;
        self.resolutionDisplayView.clipsToBounds = YES;
        UITapGestureRecognizer *resolutionDisplayViewTap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(resolutionDisplayViewTapped:)];
        [self.resolutionDisplayView addGestureRecognizer:resolutionDisplayViewTap];
        
        resolutionTable[0] = CGSizeMake(640, 360);
        resolutionTable[1] = CGSizeMake(1280, 720);
        resolutionTable[2] = CGSizeMake(1920, 1080);
        resolutionTable[3] = CGSizeMake(3840, 2160);
        resolutionTable[4] = CGSizeMake(safeAreaWidth, fullScreenHeight);
        resolutionTable[5] = CGSizeMake(fullScreenWidth, fullScreenHeight);
        resolutionTable[6] = CGSizeMake([currentSettings.width integerValue], [currentSettings.height integerValue]); // custom initial value
        [self updateResolutionTable];
        
        // Don't populate the custom entry unless we have a custom resolution
        if (!isCustomResolution(resolutionTable[6])) {
            resolutionTable[6] = CGSizeMake(0, 0);
        }
        
        NSInteger framerate;
        switch ([currentSettings.framerate integerValue]) {
            case 30:
                framerate = 0;
                break;
            default:
            case 60:
                framerate = 1;
                break;
            case 120:
                framerate = 2;
                break;
        }
        
        NSInteger resolution = currentSettings.resolutionSelected.integerValue;
        if(resolution >= RESOLUTION_TABLE_SIZE){
            resolution = 0;
        }
        
        // Only show the 120 FPS option if we have a > 60-ish Hz display
        bool enable120Fps = false;
        if (@available(iOS 10.3, tvOS 10.3, *)) {
            if ([UIScreen mainScreen].maximumFramesPerSecond > 62) {
                enable120Fps = true;
            }
        }
        if (!enable120Fps) {
            [self.framerateSelector removeSegmentAtIndex:2 animated:NO];
        }
        
        // Disable codec selector segments for unsupported codecs
#if defined(__IPHONE_16_0) || defined(__TVOS_16_0)
        if (!VTIsHardwareDecodeSupported(kCMVideoCodecType_AV1))
#endif
        {
            [self.codecSelector removeSegmentAtIndex:2 animated:NO];
        }
        if (!VTIsHardwareDecodeSupported(kCMVideoCodecType_HEVC)) {
            [self.codecSelector removeSegmentAtIndex:1 animated:NO];
            
            // Only enable the 4K option for "recent" devices. We'll judge that by whether
            // they support HEVC decoding (A9 or later).
            [self.resolutionSelector setEnabled:NO forSegmentAtIndex:3];
        }
        switch (currentSettings.preferredCodec) {
            case CODEC_PREF_AUTO:
                [self.codecSelector setSelectedSegmentIndex:self.codecSelector.numberOfSegments - 1];
                break;
                
            case CODEC_PREF_AV1:
                [self.codecSelector setSelectedSegmentIndex:2];
                break;
                
            case CODEC_PREF_HEVC:
                [self.codecSelector setSelectedSegmentIndex:1];
                break;
                
            case CODEC_PREF_H264:
                [self.codecSelector setSelectedSegmentIndex:0];
                break;
        }
        
        if (!VTIsHardwareDecodeSupported(kCMVideoCodecType_HEVC) || !(AVPlayer.availableHDRModes & AVPlayerHDRModeHDR10)) {
            [self.hdrSelector removeAllSegments];
            [self.hdrSelector insertSegmentWithTitle:[LocalizationHelper localizedStringForKey:@"Unsupported on this device"] atIndex:0 animated:NO];
            [self.hdrSelector setEnabled:NO];
        }
        else {
            [self.hdrSelector setSelectedSegmentIndex:currentSettings.enableHdr ? 1 : 0];
        }
        
        [self.yuv444Selector setSelectedSegmentIndex:currentSettings.enableYUV444 ? 1 : 0];
        [self.statsOverlaySelector setSelectedSegmentIndex:currentSettings.statsOverlayLevel.intValue];
        [self.btMouseSelector setSelectedSegmentIndex:currentSettings.btMouseSupport ? 1 : 0];
        [self.optimizeSettingsSelector setSelectedSegmentIndex:currentSettings.optimizeGames ? 1 : 0];
        [self.framePacingSelector setSelectedSegmentIndex:currentSettings.useFramePacing ? 1 : 0];
        [self.multiControllerSelector setSelectedSegmentIndex:currentSettings.multiController ? 1 : 0];
        [self.swapABXYButtonsSelector setSelectedSegmentIndex:currentSettings.swapABXYButtons ? 1 : 0];
        [self.audioOnPCSelector setSelectedSegmentIndex:currentSettings.playAudioOnPC ? 1 : 0];
        _lastSelectedResolutionIndex = resolution;
        [self.resolutionSelector setSelectedSegmentIndex:resolution];
        [self.resolutionSelector addTarget:self action:@selector(newResolutionChosen) forControlEvents:UIControlEventValueChanged];
        [self.framerateSelector setSelectedSegmentIndex:framerate];
        [self.framerateSelector addTarget:self action:@selector(updateBitrate) forControlEvents:UIControlEventValueChanged];
        [self.bitrateSlider setMinimumValue:0];
        [self.bitrateSlider setMaximumValue:(sizeof(bitrateTable) / sizeof(*bitrateTable)) - 1];
        [self.bitrateSlider setValue:[self getSliderValueForBitrate:_bitrate] animated:YES];
        [self.bitrateSlider addTarget:self action:@selector(bitrateSliderMoved) forControlEvents:UIControlEventValueChanged];
        [self updateBitrateText];
        [self updateResolutionDisplayViewText];
        
        // Unlock Display Orientation setting
        bool unlockDisplayOrientationSelectorEnabled = [self isFullScreenRequired];//need "requires fullscreen" enabled in the app bunddle to make runtime orientation limitation woring
        if(unlockDisplayOrientationSelectorEnabled) [self.unlockDisplayOrientationSelector setSelectedSegmentIndex:currentSettings.unlockDisplayOrientation ? 1 : 0];
        else [self.unlockDisplayOrientationSelector setSelectedSegmentIndex:1]; // can't lock screen orientation in this mode = Display Orientation always unlocked
        [self.unlockDisplayOrientationSelector setEnabled:unlockDisplayOrientationSelectorEnabled];
        
        
        // lift streamview setting
        [self.liftStreamViewForKeyboardSelector setSelectedSegmentIndex:currentSettings.liftStreamViewForKeyboard ? 1 : 0];// Load old setting
        
        // showkeyboard toolbar setting
        [self.showKeyboardToolbarSelector setSelectedSegmentIndex:currentSettings.showKeyboardToolbar ? 1 : 0];// Load old setting
        
        // reverse mouse wheel direction setting
        [self.reverseMouseWheelDirectionSelector setSelectedSegmentIndex:currentSettings.reverseMouseWheelDirection ? 1 : 0];// Load old setting
        
        //  slide to menu settings
        [self.slideToSettingsScreenEdgeSelector setSelectedSegmentIndex:[self getSelectorIndexFromScreenEdge:(uint32_t)currentSettings.slideToSettingsScreenEdge.integerValue]];
        // Load old setting
        [self.cmdToolScreenEdgeSelector setEnabled:false];
        [self.slideToSettingsScreenEdgeSelector addTarget:self action:@selector(slideToSettingsScreenEdgeChanged) forControlEvents:UIControlEventValueChanged];
        [self slideToSettingsScreenEdgeChanged];
        
        [self.slideToMenuDistanceSlider setValue:currentSettings.slideToSettingsDistance.floatValue];
        [self.slideToMenuDistanceSlider addTarget:self action:@selector(slideToMenuDistanceSliderMoved) forControlEvents:(UIControlEventValueChanged)]; // Update label display when slider is being moved.
        [self slideToMenuDistanceSliderMoved];
        
        
        
        //TouchMode & OSC Related Settings:
        
        // pointer veloc setting, will be enable/disabled by touchMode
        [self.pointerVelocityModeDividerSlider setValue: (uint8_t)(currentSettings.pointerVelocityModeDivider.floatValue * 100) animated:YES]; // Load old setting.
        [self.pointerVelocityModeDividerSlider addTarget:self action:@selector(pointerVelocityModeDividerSliderMoved) forControlEvents:(UIControlEventValueChanged)]; // Update label display when slider is being moved.
        [self pointerVelocityModeDividerSliderMoved];
        
        // init pointer veloc setting,  will be enable/disabled by touchMode
        [self.touchPointerVelocityFactorSlider setValue: [self map_SliderValue_fromVelocFactor: currentSettings.touchPointerVelocityFactor.floatValue] animated:YES]; // Load old setting.
        [self.touchPointerVelocityFactorSlider addTarget:self action:@selector(touchPointerVelocityFactorSliderMoved) forControlEvents:(UIControlEventValueChanged)]; // Update label display when slider is being moved.
        [self touchPointerVelocityFactorSliderMoved];
        
        // async native touch event
        [self.asyncNativeTouchPrioritySelector setSelectedSegmentIndex:currentSettings.asyncNativeTouchPriority.intValue]; // load old setting of asyncNativeTouchPriority
        [self.asyncNativeTouchPrioritySelector addTarget:self action:@selector(asyncNativeTouchPriorityChanged) forControlEvents:UIControlEventValueChanged];
        [self asyncNativeTouchPriorityChanged];
        
        // init relative touch mouse pointer veloc setting,  will be enable/disabled by touchMode
        [self.mousePointerVelocityFactorSlider setValue:[self map_SliderValue_fromVelocFactor: currentSettings.mousePointerVelocityFactor.floatValue] animated:YES]; // Load old setting.
        [self.mousePointerVelocityFactorSlider addTarget:self action:@selector(mousePointerVelocityFactorSliderMoved) forControlEvents:(UIControlEventValueChanged)]; // Update label display when slider is being moved.
        [self mousePointerVelocityFactorSliderMoved];
        
        
        // these settings will be affected by onscreenControl & touchMode, must be loaded before them.
        // NSLog(@"osc tool fingers setting test: %d", currentSettings.oscLayoutToolFingers.intValue);
        self->oscLayoutFingers = (uint16_t)currentSettings.oscLayoutToolFingers.intValue; // load old setting of oscLayoutFingers
        [self.keyboardToggleFingerNumSlider setValue:(CGFloat)currentSettings.keyboardToggleFingers.intValue animated:YES]; // Load old setting. old setting was converted to uint16_t before saving.
        [self.keyboardToggleFingerNumSlider addTarget:self action:@selector(keyboardToggleFingerNumSliderMoved) forControlEvents:(UIControlEventValueChanged)]; // Update label display when slider is being moved.
        [self keyboardToggleFingerNumSliderMoved];
        
        // this setting will be affected by touchMode, must be loaded before them.
        NSInteger onscreenControlsLevel = [currentSettings.onscreenControls integerValue];
        [self.onscreenControlSelector setSelectedSegmentIndex:onscreenControlsLevel];
        [self.onscreenControlSelector addTarget:self action:@selector(onscreenControlChanged) forControlEvents:UIControlEventValueChanged];
        [self onscreenControlChanged];
        
        // touch move event interval for native-touch.
        [self.touchMoveEventIntervalSlider setValue:currentSettings.touchMoveEventInterval.intValue animated:YES]; // Load old setting.
        [self.touchMoveEventIntervalSlider addTarget:self action:@selector(touchMoveEventIntervalSliderMoved) forControlEvents:(UIControlEventValueChanged)]; // Update label display when slider is being moved.
        [self touchMoveEventIntervalSliderMoved];
        
        
        // [self.touchModeSelector setSelectedSegmentIndex:currentSettings.absoluteTouchMode ? 1 : 0];
        // this part will enable/disable oscSelector & the asyncNativeTouchPriority selector
        [self.touchModeSelector setSelectedSegmentIndex:currentSettings.touchMode.intValue]; //Load old touchMode setting
        [self.touchModeSelector addTarget:self action:@selector(touchModeChanged) forControlEvents:UIControlEventValueChanged];
        [self touchModeChanged];
        
        
        // init CustomOSC stuff
        /* sets a reference to the correct 'LayoutOnScreenControlsViewController' depending on whether the user is on an iPhone or iPad */
        self.layoutOnScreenControlsVC = [[LayoutOnScreenControlsViewController alloc] init];
        BOOL isIPhone = ([UIDevice currentDevice].userInterfaceIdiom == UIUserInterfaceIdiomPhone);
        if (isIPhone) {
            UIStoryboard *storyboard = [UIStoryboard storyboardWithName:@"iPhone" bundle:nil];
            self.layoutOnScreenControlsVC = [storyboard instantiateViewControllerWithIdentifier:@"LayoutOnScreenControlsViewController"];
        }
        else {
            UIStoryboard *storyboard = [UIStoryboard storyboardWithName:@"iPad" bundle:nil];
            self.layoutOnScreenControlsVC = [storyboard instantiateViewControllerWithIdentifier:@"LayoutOnScreenControlsViewController"];
            self.layoutOnScreenControlsVC.modalPresentationStyle = UIModalPresentationFullScreen;
        }
        
        [self.externalDisplayModeSelector setSelectedSegmentIndex:currentSettings.externalDisplayMode.integerValue];
        [self.localMousePointerModeSelector setSelectedSegmentIndex:currentSettings.localMousePointerMode.integerValue];
    }];
}

- (void)slideToSettingsScreenEdgeChanged{
    if([self.slideToSettingsScreenEdgeSelector selectedSegmentIndex] == 0) [self.cmdToolScreenEdgeSelector setSelectedSegmentIndex:1];
    else [self.cmdToolScreenEdgeSelector setSelectedSegmentIndex:0];
}


- (void)updateTouchModeLabel{
    NSString* labelText;
    switch([self.touchModeSelector selectedSegmentIndex]){
        case RELATIVE_TOUCH:
            labelText = [LocalizationHelper localizedStringForKey:@"Touch Mode - Double Tap to Drag, OSC Available"];break;
        case REGULAR_NATIVE_TOUCH:
            labelText = [LocalizationHelper localizedStringForKey:@"Touch Mode - With OSC & Mouse Support"];break;
        case PURE_NATIVE_TOUCH:
            labelText = [LocalizationHelper localizedStringForKey:@"Touch Mode - No OSC & Mouse Support"];break;
        case ABSOLUTE_TOUCH:
            labelText = [LocalizationHelper localizedStringForKey:@"Touch Mode - For MacOS Direct Touch"];break;
    }
    [self.touchModeLabel setText:labelText];
}

- (void)showCustomOSCTip {
    NSString* edgeSide = self.slideToSettingsScreenEdgeSelector.selectedSegmentIndex == 1 ? [LocalizationHelper localizedStringForKey:@"left"] : [LocalizationHelper localizedStringForKey:@"right"];
    UIAlertController *alertController = [UIAlertController alertControllerWithTitle:[LocalizationHelper localizedStringForKey:@"Rebase in Streaming"]
                                                                             message:[LocalizationHelper localizedStringForKey:@"Open widget tool in streaming by:\nSliding from %@ screen edge to open cmd tool.\nOr tap %d fingers on stream view, number of fingers required:", edgeSide, self->oscLayoutFingers]
                                                                      preferredStyle:UIAlertControllerStyleAlert];
    
    [alertController addTextFieldWithConfigurationHandler:^(UITextField *textField) {
        textField.placeholder = [LocalizationHelper localizedStringForKey:@"%d", self->oscLayoutFingers];
        textField.keyboardType = UIKeyboardTypeNumberPad;
    }];
    
    UIAlertAction *cancelAction = [UIAlertAction actionWithTitle:[LocalizationHelper localizedStringForKey:@"Cancel"]
                                                           style:UIAlertActionStyleDefault
                                                         handler:nil];
    
    UIAlertAction *okAction = [UIAlertAction actionWithTitle:[LocalizationHelper localizedStringForKey:@"OK"]
                                                       style:UIAlertActionStyleDefault
                                                     handler:^(UIAlertAction *action) {
                                                         UITextField *textField = alertController.textFields.firstObject;
                                                         NSString *inputText = textField.text;
                                                         NSInteger fingers = [inputText integerValue];
                                                         if (inputText.length > 0 && fingers >= 4) {
                                                             self->oscLayoutFingers = (uint16_t) fingers;
                                                             NSLog(@"OK button tapped with %d fingers", (uint16_t)fingers);
                                                         } else {
                                                             NSLog(@"OK button tapped with no change");
                                                         }
                                                         
                                                         // Continue execution after the alert is dismissed
                                                         if (!self->_mainFrameViewController.settingsExpandedInStreamView) {
                                                             [self invokeOscLayout]; // Don't open osc layout tool immediately during streaming
                                                         }
                                                         
                                                        [self.onscreenControllerLabel setText:[LocalizationHelper localizedStringForKey: @"Tap %d Fingers to Change OSC Layout in Stream View", self->oscLayoutFingers]]; //update the osc label
                                                        [self keyboardToggleFingerNumSliderMoved]; //update keyboard toggle number;
                                                     }];
    
    [alertController addAction:cancelAction];
    [alertController addAction:okAction];
    [self presentViewController:alertController animated:YES completion:nil];
}



- (bool) isOnScreenControllerOrButtonEnabled{
    return ([self.touchModeSelector selectedSegmentIndex] == RELATIVE_TOUCH || [self.touchModeSelector selectedSegmentIndex] == REGULAR_NATIVE_TOUCH || [self.touchModeSelector selectedSegmentIndex] == ABSOLUTE_TOUCH) && [self.onscreenControlSelector selectedSegmentIndex] != OnScreenControlsLevelOff;
}



- (void)onscreenControlChanged{
    
    BOOL isIPhone = ([UIDevice currentDevice].userInterfaceIdiom == UIUserInterfaceIdiomPhone);
    if (isIPhone) {
        UIStoryboard *storyboard = [UIStoryboard storyboardWithName:@"iPhone" bundle:nil];
        self.layoutOnScreenControlsVC = [storyboard instantiateViewControllerWithIdentifier:@"LayoutOnScreenControlsViewController"];
    }
    else {
        UIStoryboard *storyboard = [UIStoryboard storyboardWithName:@"iPad" bundle:nil];
        self.layoutOnScreenControlsVC = [storyboard instantiateViewControllerWithIdentifier:@"LayoutOnScreenControlsViewController"];
        self.layoutOnScreenControlsVC.modalPresentationStyle = UIModalPresentationFullScreen;
    }
    
    bool customOscEnabled = [self isOnScreenControllerOrButtonEnabled] && [self.onscreenControlSelector selectedSegmentIndex] == OnScreenControlsLevelCustom;
    // [self widget:self.keyboardToggleFingerNumSlider setEnabled:!customOscEnabled];
    if(customOscEnabled && !justEnteredSettingsViewDoNotOpenOscLayoutTool) {
        // [self.keyboardToggleFingerNumSlider setValue:3.0];
        // [self keyboardToggleFingerNumSliderMoved];
        [self keyboardToggleFingerNumSliderMoved]; // go to exclude 5 fingers
        [self.onscreenControllerLabel setText:[LocalizationHelper localizedStringForKey: @"Tap %d Fingers to Change OSC Layout in Stream View", self->oscLayoutFingers]];
        [self showCustomOSCTip];
        justEnteredSettingsViewDoNotOpenOscLayoutTool = false;
        //if (self.layoutOnScreenControlsVC.isBeingPresented == NO)
    }
    else{
        [self.onscreenControllerLabel setText:[LocalizationHelper localizedStringForKey: @"On-Screen Controls & Widgets"]];
    }
    justEnteredSettingsViewDoNotOpenOscLayoutTool = false;
}

- (void)invokeOscLayout{
    self.layoutOnScreenControlsVC.view.backgroundColor = [UIColor colorWithWhite:0.55 alpha:1.0];
    [self presentViewController:self.layoutOnScreenControlsVC animated:YES completion:nil];
}


- (void) pointerVelocityModeDividerSliderMoved {
    [self.pointerVelocityModeDividerUILabel setText:[LocalizationHelper localizedStringForKey:@"Touch Pointer Velocity: Scaled on %d%% of Right Screen", 100 - (uint8_t)self.pointerVelocityModeDividerSlider.value]];
}

- (void) touchPointerVelocityFactorSliderMoved {
    [self.touchPointerVelocityFactorUILabel setText:[LocalizationHelper localizedStringForKey: @"Touch Pointer Velocity: %d%%",  [self map_velocFactorDisplay_fromSliderValue: self.touchPointerVelocityFactorSlider.value]]]; // Update label display
}


// veloc factor upto 700%
- (uint16_t) map_velocFactorDisplay_fromSliderValue:(CGFloat)sliderValue{
    uint16_t velocFactorDisplay = 0;
    if(sliderValue > 200) velocFactorDisplay = 200 + ((uint16_t)sliderValue % 200) * 5;
    else velocFactorDisplay = (uint16_t) sliderValue;
    return velocFactorDisplay;
}

// veloc factor upto 700%

- (CGFloat) map_SliderValue_fromVelocFactor:(CGFloat)velocFactor{
    CGFloat sliderValue = 0.0f;
    if(velocFactor < 2.0f) sliderValue = velocFactor * 100;
    else sliderValue = (velocFactor - 2.0) * 100 / 5 + 200;
    return sliderValue;
}

- (void) mousePointerVelocityFactorSliderMoved {
    [self.mousePointerVelocityFactorUILabel setText:[LocalizationHelper localizedStringForKey: @"Mouse Pointer Velocity: %d%%",  [self map_velocFactorDisplay_fromSliderValue: self.mousePointerVelocityFactorSlider.value]]]; // Update label display
}

- (uint32_t) getScreenEdgeFromSelector {
    switch (self.slideToSettingsScreenEdgeSelector.selectedSegmentIndex) {
        case 0: return UIRectEdgeLeft;
        case 1: return UIRectEdgeRight;
        case 2: return UIRectEdgeLeft|UIRectEdgeRight;
        default: return UIRectEdgeLeft;
    }
}

- (uint32_t) getSelectorIndexFromScreenEdge: (uint32_t)edge {
    switch (edge) {
        case UIRectEdgeLeft: return 0;
        case UIRectEdgeRight: return 1;
        case UIRectEdgeLeft|UIRectEdgeRight: return 2;
        default: return 0;
    }
    return 0;
}

- (void) widget:(UISlider*)widget setEnabled:(bool)enabled{
    [widget setEnabled:enabled];
    if(enabled){
        widget.alpha = 1.0;
        [widget setValue:widget.value + 0.0001]; // this is for low iOS version (like iOS14), only setting this minor value change is able to make widget visibility clear
    }
    else widget.alpha = 0.5; // this is for updating widget visibility on low iOS version like mini5 ios14
}

- (void) asyncNativeTouchPriorityChanged {
    bool isNativeTouch = [self.touchModeSelector selectedSegmentIndex] == PURE_NATIVE_TOUCH || [self.touchModeSelector selectedSegmentIndex] == REGULAR_NATIVE_TOUCH;
    bool asyncNativeTouchEnabled = [self.asyncNativeTouchPrioritySelector selectedSegmentIndex] != AsyncNativeTouchOff;
    [self widget:self.touchMoveEventIntervalSlider setEnabled:isNativeTouch && asyncNativeTouchEnabled];
}

- (void) touchModeChanged {
    // Disable On-Screen Controls & Widgets in non-relative touch mode
    bool oscSelectorEnabled = [self.touchModeSelector selectedSegmentIndex] == RELATIVE_TOUCH || [self.touchModeSelector selectedSegmentIndex] == REGULAR_NATIVE_TOUCH || [self.touchModeSelector selectedSegmentIndex] == ABSOLUTE_TOUCH;
    bool customOscEnabled = [self isOnScreenControllerOrButtonEnabled] && [self.onscreenControlSelector selectedSegmentIndex] == OnScreenControlsLevelCustom;
    bool isNativeTouch = [self.touchModeSelector selectedSegmentIndex] == PURE_NATIVE_TOUCH || [self.touchModeSelector selectedSegmentIndex] == REGULAR_NATIVE_TOUCH;
    bool asyncNativeTouchEnabled = [self.asyncNativeTouchPrioritySelector selectedSegmentIndex] != AsyncNativeTouchOff;
    
    [self.onscreenControlSelector setEnabled:oscSelectorEnabled];
    [self.asyncNativeTouchPrioritySelector setEnabled:isNativeTouch]; // this selector stay aligned with oscSelector
    [self widget:self.touchMoveEventIntervalSlider setEnabled:isNativeTouch && asyncNativeTouchEnabled]; // applies to native touch modes only
    [self widget:self.pointerVelocityModeDividerSlider setEnabled:isNativeTouch]; // pointer velocity scaling works only in native touch mode.
    [self widget:self.touchPointerVelocityFactorSlider setEnabled:isNativeTouch]; // pointer velocity scaling works only in native touch mode.
    [self widget:self.mousePointerVelocityFactorSlider setEnabled:[self.touchModeSelector selectedSegmentIndex] == RELATIVE_TOUCH]; // mouse velocity scaling works only in relative touch mode.

    // number of touches required to toggle keyboard will be fixed to 3 when OSC is enabled.
    // [self widget:self.keyboardToggleFingerNumSlider setEnabled: !customOscEnabled];  // cancel OSC limitation for regular native touch,
    // when CustomOSC is enabled:
    if(customOscEnabled) {
        // [self.keyboardToggleFingerNumSlider setValue:3.0];
        // [self.keyboardToggleFingerNumLabel setText:[LocalizationHelper localizedStringForKey:@"To Toggle Local Keyboard: Tap %d Fingers", (uint16_t)self.keyboardToggleFingerNumSlider.value]];
        [self.onscreenControllerLabel setText:[LocalizationHelper localizedStringForKey: @"Tap %d Fingers to Change OSC Layout in Stream View", self->oscLayoutFingers]];
        [self keyboardToggleFingerNumSliderMoved]; // go exclude 5 fingers
        //if (self.layoutOnScreenControlsVC.isBeingPresented == NO)
    }
    else{
        [self.onscreenControllerLabel setText:[LocalizationHelper localizedStringForKey: @"On-Screen Controls & Widgets"]];
    }
    [self updateTouchModeLabel];
}

- (void) updateBitrate {
    NSInteger fps = [self getChosenFrameRate];
    NSInteger width = [self getChosenStreamWidth];
    NSInteger height = [self getChosenStreamHeight];
    NSInteger defaultBitrate;
    
    // This logic is shamelessly stolen from Moonlight Qt:
    // https://github.com/moonlight-stream/moonlight-qt/blob/master/app/settings/streamingpreferences.cpp
    
    // Don't scale bitrate linearly beyond 60 FPS. It's definitely not a linear
    // bitrate increase for frame rate once we get to values that high.
    float frameRateFactor = (fps <= 60 ? fps : (sqrtf(fps / 60.f) * 60.f)) / 30.f;

    // TODO: Collect some empirical data to see if these defaults make sense.
    // We're just using the values that the Shield used, as we have for years.
    struct {
        NSInteger pixels;
        int factor;
    } resTable[] = {
        { 640 * 360, 1 },
        { 854 * 480, 2 },
        { 1280 * 720, 5 },
        { 1920 * 1080, 10 },
        { 2560 * 1440, 20 },
        { 3840 * 2160, 40 },
        { -1, -1 }
    };

    // Calculate the resolution factor by linear interpolation of the resolution table
    float resolutionFactor;
    NSInteger pixels = width * height;
    for (int i = 0;; i++) {
        if (pixels == resTable[i].pixels) {
            // We can bail immediately for exact matches
            resolutionFactor = resTable[i].factor;
            break;
        }
        else if (pixels < resTable[i].pixels) {
            if (i == 0) {
                // Never go below the lowest resolution entry
                resolutionFactor = resTable[i].factor;
            }
            else {
                // Interpolate between the entry greater than the chosen resolution (i) and the entry less than the chosen resolution (i-1)
                resolutionFactor = ((float)(pixels - resTable[i-1].pixels) / (resTable[i].pixels - resTable[i-1].pixels)) * (resTable[i].factor - resTable[i-1].factor) + resTable[i-1].factor;
            }
            break;
        }
        else if (resTable[i].pixels == -1) {
            // Never go above the highest resolution entry
            resolutionFactor = resTable[i-1].factor;
            break;
        }
    }

    defaultBitrate = round(resolutionFactor * frameRateFactor) * 1000;
    _bitrate = MIN(defaultBitrate, 100000);
    [self.bitrateSlider setValue:[self getSliderValueForBitrate:_bitrate] animated:YES];
    
    [self updateBitrateText];
}

- (void) newResolutionChosen {
    BOOL lastSegmentSelected = [self.resolutionSelector selectedSegmentIndex] + 1 == [self.resolutionSelector numberOfSegments];
    if (lastSegmentSelected) {
        [self promptCustomResolutionDialog];
    }
    else {
        [self updateBitrate];
        [self updateResolutionDisplayViewText];
        _lastSelectedResolutionIndex = [self.resolutionSelector selectedSegmentIndex];
    }
    [self updateResolutionTable];
}

- (void) promptCustomResolutionDialog {
    UIAlertController *alertController = [UIAlertController alertControllerWithTitle:[LocalizationHelper localizedStringForKey: @"Enter Custom Resolution"] message:nil preferredStyle:UIAlertControllerStyleAlert];

    [alertController addTextFieldWithConfigurationHandler:^(UITextField *textField) {
        textField.placeholder = [LocalizationHelper localizedStringForKey:@"Video Width"];
        textField.clearButtonMode = UITextFieldViewModeAlways;
        textField.borderStyle = UITextBorderStyleRoundedRect;
        textField.keyboardType = UIKeyboardTypeNumberPad;
        
        if (resolutionTable[RESOLUTION_TABLE_CUSTOM_INDEX].width == 0) {
            textField.text = @"";
        }
        else {
            textField.text = [NSString stringWithFormat:@"%d", (int) resolutionTable[RESOLUTION_TABLE_CUSTOM_INDEX].width];
        }
    }];

    [alertController addTextFieldWithConfigurationHandler:^(UITextField *textField) {
        textField.placeholder = [LocalizationHelper localizedStringForKey:@"Video Height"];
        textField.clearButtonMode = UITextFieldViewModeAlways;
        textField.borderStyle = UITextBorderStyleRoundedRect;
        textField.keyboardType = UIKeyboardTypeNumberPad;
        
        if (resolutionTable[RESOLUTION_TABLE_CUSTOM_INDEX].height == 0) {
            textField.text = @"";
        }
        else {
            textField.text = [NSString stringWithFormat:@"%d", (int) resolutionTable[RESOLUTION_TABLE_CUSTOM_INDEX].height];
        }
    }];

    [alertController addAction:[UIAlertAction actionWithTitle:[LocalizationHelper localizedStringForKey:@"Ok"] style:UIAlertActionStyleDefault handler:^(UIAlertAction *action) {
        NSArray * textfields = alertController.textFields;
        UITextField *widthField = textfields[0];
        UITextField *heightField = textfields[1];
        
        long width = [widthField.text integerValue];
        long height = [heightField.text integerValue];
        if (width <= 0 || height <= 0) {
            // Restore the previous selection
            [self.resolutionSelector setSelectedSegmentIndex:self->_lastSelectedResolutionIndex];
            return;
        }
        
        // H.264 maximum
        int maxResolutionDimension = 4096;
        if (@available(iOS 11.0, tvOS 11.0, *)) {
            if (VTIsHardwareDecodeSupported(kCMVideoCodecType_HEVC)) {
                // HEVC maximum
                maxResolutionDimension = 8192;
            }
        }
        
        // Cap to maximum valid dimensions
        width = MIN(width, maxResolutionDimension);
        height = MIN(height, maxResolutionDimension);
        
        // Cap to minimum valid dimensions
        width = MAX(width, 256);
        height = MAX(height, 256);

        resolutionTable[RESOLUTION_TABLE_CUSTOM_INDEX] = CGSizeMake(width, height);
        [self updateBitrate];
        [self updateResolutionDisplayViewText];
        self->_lastSelectedResolutionIndex = [self.resolutionSelector selectedSegmentIndex];
        
        UIAlertController *alertController = [UIAlertController alertControllerWithTitle:[LocalizationHelper localizedStringForKey:@"Custom Resolution Selected"] message: [LocalizationHelper localizedStringForKey:@"Custom resolutions are not officially supported by GeForce Experience, so it will not set your host display resolution. You will need to set it manually while in game.\n\nResolutions that are not supported by your client or host PC may cause streaming errors."] preferredStyle:UIAlertControllerStyleAlert];
        [alertController addAction:[UIAlertAction actionWithTitle:[LocalizationHelper localizedStringForKey:@"Ok"] style:UIAlertActionStyleDefault handler:nil]];
        [self presentViewController:alertController animated:YES completion:nil];
    }]];

    [alertController addAction:[UIAlertAction actionWithTitle:[LocalizationHelper localizedStringForKey:@"Cancel"] style:UIAlertActionStyleCancel handler:^(UIAlertAction *action) {
        // Restore the previous selection
        [self.resolutionSelector setSelectedSegmentIndex:self->_lastSelectedResolutionIndex];
    }]];

    [self presentViewController:alertController animated:YES completion:nil];
}

- (void)resolutionDisplayViewTapped:(UITapGestureRecognizer *)sender {
    NSURL *url = [NSURL URLWithString:@"https://moonlight-stream.org/custom-resolution"];
    if ([[UIApplication sharedApplication] canOpenURL:url]) {
        [[UIApplication sharedApplication] openURL:url options:@{} completionHandler:nil];
    }
}

- (void) updateResolutionDisplayViewText {
    NSInteger width = [self getChosenStreamWidth];
    NSInteger height = [self getChosenStreamHeight];
    CGFloat viewFrameWidth = self.resolutionDisplayView.frame.size.width;
    CGFloat viewFrameHeight = self.resolutionDisplayView.frame.size.height;
    CGFloat padding = 10;
    CGFloat fontSize = [UIFont smallSystemFontSize];
    
    for (UIView *subview in self.resolutionDisplayView.subviews) {
        [subview removeFromSuperview];
    }
    UILabel *label1 = [[UILabel alloc] init];
    label1.text = [LocalizationHelper localizedStringForKey:@"Set PC/Game resolution:"];
    label1.font = [UIFont systemFontOfSize:fontSize];
    [label1 sizeToFit];
    label1.frame = CGRectMake(padding, (viewFrameHeight - label1.frame.size.height) / 2, label1.frame.size.width, label1.frame.size.height);

    UILabel *label2 = [[UILabel alloc] init];
    label2.text = [NSString stringWithFormat:@"%ld x %ld", (long)width, (long)height];
    [label2 sizeToFit];
    label2.frame = CGRectMake(viewFrameWidth - label2.frame.size.width - padding, (viewFrameHeight - label2.frame.size.height) / 2, label2.frame.size.width, label2.frame.size.height);

    [self.resolutionDisplayView addSubview:label1];
    [self.resolutionDisplayView addSubview:label2];
}

- (void) touchMoveEventIntervalSliderMoved{
    [self.touchMoveEventIntervalLabel setText:[LocalizationHelper localizedStringForKey:@"Interval of Multi-Touch Move Events: %d μs", (uint16_t)self.touchMoveEventIntervalSlider.value]];
}

- (void) keyboardToggleFingerNumSliderMoved{
    // bool oscEnabled = [self isOnScreenControllerOrButtonEnabled];
    bool customOscEnabled = [self isOnScreenControllerOrButtonEnabled] && [self.onscreenControlSelector selectedSegmentIndex] == OnScreenControlsLevelCustom;
    
    CGFloat sliderValue = self.keyboardToggleFingerNumSlider.value;
    if(customOscEnabled){
        // exclude self->oscLayoutFingers when custom osc is enabled
        if(sliderValue > self->oscLayoutFingers - 1 && sliderValue < self->oscLayoutFingers) [self.keyboardToggleFingerNumSlider setValue: self->oscLayoutFingers - 1];
        if(sliderValue >= self->oscLayoutFingers && sliderValue < self->oscLayoutFingers + 1) [self.keyboardToggleFingerNumSlider setValue: self->oscLayoutFingers + 1];
    }
        
    sliderValue = self.keyboardToggleFingerNumSlider.value;
    if(sliderValue > 10.5f) [self.keyboardToggleFingerNumLabel setText:[LocalizationHelper localizedStringForKey:@"Local Keyboard Toggle Disabled"]];
    else [self.keyboardToggleFingerNumLabel setText:[LocalizationHelper localizedStringForKey:@"To Toggle Local Keyboard: Tap %d Fingers", (uint16_t)sliderValue]]; // Initiate label display, exclude 5 fingers.
}

- (void) slideToMenuDistanceSliderMoved{
    [self.slideToSettingsDistanceUILabel setText:[LocalizationHelper localizedStringForKey:@"Slide Distance for in-Stream Menu: %.2f * screen-width", self.slideToMenuDistanceSlider.value]];
}

- (void) bitrateSliderMoved {
    assert(self.bitrateSlider.value < (sizeof(bitrateTable) / sizeof(*bitrateTable)));
    _bitrate = bitrateTable[(int)self.bitrateSlider.value];
    [self updateBitrateText];
}

- (void) updateBitrateText {
    // Display bitrate in Mbps
    if(_bitrate / 1000. > 50.0) [self.bitrateLabel setText:[LocalizationHelper localizedStringForKey:@"Bitrate: %.1f Mbps - Use High Bitrates with Caution!", _bitrate / 1000.]];
    else [self.bitrateLabel setText:[LocalizationHelper localizedStringForKey:@"Bitrate: %.1f Mbps", _bitrate / 1000.]];
}

- (NSInteger) getChosenFrameRate {
    switch ([self.framerateSelector selectedSegmentIndex]) {
        case 0:
            return 30;
        case 1:
            return 60;
        case 2:
            return 120;
        default:
            abort();
    }
}

- (uint32_t) getChosenCodecPreference {
    // Auto is always the last segment
    if (self.codecSelector.selectedSegmentIndex == self.codecSelector.numberOfSegments - 1) {
        return CODEC_PREF_AUTO;
    }
    else {
        switch (self.codecSelector.selectedSegmentIndex) {
            case 0:
                return CODEC_PREF_H264;
                
            case 1:
                return CODEC_PREF_HEVC;
                
            case 2:
                return CODEC_PREF_AV1;
                
            default:
                abort();
        }
    }
}

- (NSInteger) getChosenStreamHeight {
    // because the 4k resolution can be removed
    BOOL lastSegmentSelected = [self.resolutionSelector selectedSegmentIndex] + 1 == [self.resolutionSelector numberOfSegments];
    if (lastSegmentSelected) {
        return resolutionTable[RESOLUTION_TABLE_CUSTOM_INDEX].height;
    }

    return resolutionTable[[self.resolutionSelector selectedSegmentIndex]].height;
}

- (NSInteger) getChosenStreamWidth {
    // because the 4k resolution can be removed
    BOOL lastSegmentSelected = [self.resolutionSelector selectedSegmentIndex] + 1 == [self.resolutionSelector numberOfSegments];
    if (lastSegmentSelected) {
        return resolutionTable[RESOLUTION_TABLE_CUSTOM_INDEX].width;
    }

    return resolutionTable[[self.resolutionSelector selectedSegmentIndex]].width;
}

- (UIStackView *)findFlatStackViewFrom:(UIView *)view {
    while (view != nil) {
        if ([view isKindOfClass:[UIStackView class]]) {
            UIStackView *stack = (UIStackView *)view;
            BOOL hasNestedStack = NO;
            for (UIView *sub in stack.arrangedSubviews) {
                if ([sub isKindOfClass:[UIStackView class]]) {
                    hasNestedStack = YES;
                    break;
                }
            }
            if (!hasNestedStack) {
                return stack;
            }
        }
        view = view.superview;
    }
    return nil;
}


- (void)updateThemeForLabels:(UIView *)view {
    for (UIView *subview in view.subviews) {
        if ([subview isKindOfClass:[UILabel class]]) {
            UILabel *label = (UILabel *)subview;
            if (@available(iOS 13.0, *)) {
                label.layer.filters = nil;
                label.textColor = [ThemeManager textColor];
            } else {
                // Fallback on earlier versions
            }
        }
        [self updateThemeForLabels:subview];
    }
}

- (void)updateThemeForSelectors:(UIView *)view {
    for (UIView *subview in view.subviews) {
        if ([subview isKindOfClass:[UISegmentedControl class]]) {
            UISegmentedControl *selector = (UISegmentedControl *)subview;
            if (@available(iOS 13.0, *)) {
                selector.selectedSegmentTintColor = [ThemeManager appSecondaryColor];
            } else {
                // Fallback on earlier versions
            }            
        }
        [self updateThemeForSelectors:subview];
    }
}

- (void)updateThemeForSliders:(UIView *)view {
    for (UIView *subview in view.subviews) {
        if ([subview isKindOfClass:[UISlider class]]) {
            UISlider *slider = (UISlider *)subview;
            slider.tintColor = [ThemeManager appSecondaryColor];

        }
        [self updateThemeForSliders:subview];
    }
}


- (void)updateTheme{
    self.view.backgroundColor = [ThemeManager appBackgroundColor];
    if (@available(iOS 13.0, *)) {
        [self updateThemeForLabels:self.view];
        [self updateThemeForSelectors:self.view];
        [self updateThemeForSliders:self.view];
    }
}


- (void) saveSettings {
    DataManager* dataMan = [[DataManager alloc] init];
    NSInteger framerate = [self getChosenFrameRate];
    NSInteger height = [self getChosenStreamHeight];
    NSInteger width = [self getChosenStreamWidth];
    NSInteger onscreenControls = [self.onscreenControlSelector selectedSegmentIndex];
    NSInteger keyboardToggleFingers = (uint16_t)self.keyboardToggleFingerNumSlider.value;
    NSInteger oscLayoutToolFingers = (uint16_t)self->oscLayoutFingers;
    // NSLog(@"saveSettings keyboardToggleFingers  %d", (uint16_t)keyboardToggleFingers);
    CGFloat slideToSettingsDistance = self.slideToMenuDistanceSlider.value;
    uint32_t slideToSettingsScreenEdge = [self getScreenEdgeFromSelector];
    CGFloat pointerVelocityModeDivider = (CGFloat)(uint8_t)self.pointerVelocityModeDividerSlider.value/100;
    CGFloat touchPointerVelocityFactor = (CGFloat)(uint16_t)[self map_velocFactorDisplay_fromSliderValue:self.touchPointerVelocityFactorSlider.value]/100;
    CGFloat mousePointerVelocityFactor = (CGFloat)(uint16_t)[self map_velocFactorDisplay_fromSliderValue:self.mousePointerVelocityFactorSlider.value]/100;

    // CGFloat mousePointerVelocityFactor =(CGFloat)(uint16_t)self.mousePointerVelocityFactorSlider.value/100;
    uint16_t touchMoveEventInterval = (uint16_t)self.touchMoveEventIntervalSlider.value;

    BOOL reverseMouseWheelDirection = [self.reverseMouseWheelDirectionSelector selectedSegmentIndex] == 1;
    NSInteger asyncNativeTouchPriority = [self.asyncNativeTouchPrioritySelector selectedSegmentIndex];
    BOOL liftStreamViewForKeyboard = [self.liftStreamViewForKeyboardSelector selectedSegmentIndex] == 1;
    BOOL showKeyboardToolbar = [self.showKeyboardToolbarSelector selectedSegmentIndex] == 1;
    BOOL optimizeGames = [self.optimizeSettingsSelector selectedSegmentIndex] == 1;
    BOOL multiController = [self.multiControllerSelector selectedSegmentIndex] == 1;
    BOOL swapABXYButtons = [self.swapABXYButtonsSelector selectedSegmentIndex] == 1;
    BOOL audioOnPC = [self.audioOnPCSelector selectedSegmentIndex] == 1;
    uint32_t preferredCodec = [self getChosenCodecPreference];
    BOOL enableYUV444 = [self.yuv444Selector selectedSegmentIndex] == 1;
    BOOL btMouseSupport = [self.btMouseSelector selectedSegmentIndex] == 1;
    BOOL useFramePacing = [self.framePacingSelector selectedSegmentIndex] == 1;
    // BOOL absoluteTouchMode = [self.touchModeSelector selectedSegmentIndex] == 1;
    NSInteger touchMode = [self.touchModeSelector selectedSegmentIndex];
    NSInteger statsOverlayLevel = [self.statsOverlaySelector selectedSegmentIndex];
    BOOL statsOverlayEnabled = statsOverlayLevel != 0;
    BOOL enableHdr = [self.hdrSelector selectedSegmentIndex] == 1;
    BOOL unlockDisplayOrientation = [self.unlockDisplayOrientationSelector selectedSegmentIndex] == 1;
    NSInteger resolutionSelected = [self.resolutionSelector selectedSegmentIndex];
    NSInteger externalDisplayMode = [self.externalDisplayModeSelector selectedSegmentIndex];
    NSInteger localMousePointerMode = [self.localMousePointerModeSelector selectedSegmentIndex];
    [dataMan saveSettingsWithBitrate:_bitrate
                           framerate:framerate
                              height:height
                               width:width
                         audioConfig:2 // Stereo
                    onscreenControls:onscreenControls
               keyboardToggleFingers:keyboardToggleFingers
                oscLayoutToolFingers:oscLayoutToolFingers
           slideToSettingsScreenEdge:slideToSettingsScreenEdge
                 slideToSettingsDistance:slideToSettingsDistance
          pointerVelocityModeDivider:pointerVelocityModeDivider
          touchPointerVelocityFactor:touchPointerVelocityFactor
          mousePointerVelocityFactor:mousePointerVelocityFactor
              touchMoveEventInterval:touchMoveEventInterval
          reverseMouseWheelDirection:reverseMouseWheelDirection
                   asyncNativeTouchPriority:asyncNativeTouchPriority
           liftStreamViewForKeyboard:liftStreamViewForKeyboard
                 showKeyboardToolbar:showKeyboardToolbar
                       optimizeGames:optimizeGames
                     multiController:multiController
                     swapABXYButtons:swapABXYButtons
                           audioOnPC:audioOnPC
                      preferredCodec:preferredCodec
                           enableYUV444:enableYUV444
                      useFramePacing:useFramePacing
                           enableHdr:enableHdr
                      btMouseSupport:btMouseSupport
                   // absoluteTouchMode:absoluteTouchMode
                           touchMode:touchMode
                   statsOverlayLevel:statsOverlayLevel
                        statsOverlayEnabled:statsOverlayEnabled
                       unlockDisplayOrientation:unlockDisplayOrientation
                  resolutionSelected:resolutionSelected
                 externalDisplayMode:externalDisplayMode
               localMousePointerMode:localMousePointerMode
                     settinsMenuMode:currentSettingsMenuMode];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}


#pragma mark - Navigation

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
}

@end
