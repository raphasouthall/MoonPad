//
//  HostCardView.m
//  Moonlight-ZWM
//
//  Created by True砖家 on 5/18/25.
//  Copyright © 2025 True砖家 @ Bilibili. All rights reserved.
//

#import "HostCardView.h"
#import "LocalizationHelper.h"
#import "UIColor+Theme.h"

@interface HostCardView ()

@property (nonatomic, strong) UIView *iconBackgroundView;
@property (nonatomic, strong) UIImageView *hostIconView;
@property (nonatomic, strong) UILabel *hostNameLabel;
@property (nonatomic, strong) UIImageView *statusIcon;
@property (nonatomic, strong) UILabel *statusLabel;
@property (nonatomic, strong) UIButton *leftButton;
@property (nonatomic, strong) UIButton *rightButton;
@property (nonatomic, strong) UIButton *pairButton;
@property (nonatomic, strong) UIButton *settingsButton;
@property (nonatomic, strong) NSLayoutConstraint *widthConstraint;
@property (nonatomic, strong) NSLayoutConstraint *heightConstraint;
@property (nonatomic, strong) UIView *separatorLine;
@property (nonatomic, assign) CGFloat cardContentpadding;
@property (nonatomic, assign) UIUserInterfaceStyle userIterfaceStyle;
@property (nonatomic, assign) CGSize size;


@end


@implementation HostCardView {
    TemporaryHost* _host;
    id<HostCallback> _callback;
    UIActivityIndicatorView* _hostSpinner;
    UIImageView* lockIconView;
    CGFloat computerIconMonitorCenterYOffset;
    CGFloat buttonHeight;
    CGFloat iconAndButtonSpacing;
    UIColor *defaultBlue;
    UIColor *defaultGreen;
    CAGradientLayer *backgroundLayer;

}

static const float REFRESH_CYCLE = 2.0f;


- (instancetype)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        computerIconMonitorCenterYOffset = -3.3*_sizeFactor;
        iconAndButtonSpacing = 37*_sizeFactor;
        buttonHeight = 40*_sizeFactor;
        defaultBlue = [UIColor appPrimaryColor];
        defaultGreen = [UIColor colorWithRed:52.0/255.0 green:199.0/255.0 blue:89.0/255.0 alpha:1.0];
        self.userIterfaceStyle = self.traitCollection.userInterfaceStyle;
        // self.userIterfaceStyle = UIUserInterfaceStyleLight;
        [self createBackgroundLayer];
        [self setupUI];
    }
    return self;
}

- (id) initWithHost:(TemporaryHost*)host {
    self.sizeFactor =  1.0;
    self = [self init];
    _host = host;
    
    // Use UIContextMenuInteraction on iOS 13.0+ and a standard UILongPressGestureRecognizer
    // for tvOS devices and iOS prior to 13.0.
    return self;
}

- (id) initWithHost:(TemporaryHost*)host andSizeFactor:(CGFloat)sizeFactor {
    _sizeFactor = sizeFactor;
    self = [self init];
    _host = host;
    
    // Use UIContextMenuInteraction on iOS 13.0+ and a standard UILongPressGestureRecognizer
    // for tvOS devices and iOS prior to 13.0.
    return self;
}



- (instancetype)initWithCoder:(NSCoder *)coder {
    self = [super initWithCoder:coder];
    if (self) {
        [self setupUI];
    }
    return self;
}

- (void)resizeBySizeFactor:(CGFloat)factor{
    [self.subviews makeObjectsPerformSelector:@selector(removeFromSuperview)];
    self.sizeFactor = factor;
    [self setupUI];
}

- (void)setupUI {
    self.backgroundColor = [UIColor widgetBackgroundColorDark];  // theme
    self.layer.cornerRadius = 16;
    self.cardContentpadding = 13 * _sizeFactor;
    self.clipsToBounds = YES;
    self.translatesAutoresizingMaskIntoConstraints = NO;
    CGFloat appButtonWidth = 100*_sizeFactor;
    CGFloat launchButtonWidth = 120*_sizeFactor;
    /*
    NSLayoutConstraint *topAnchorConstraint;
    topAnchorConstraint = [self.topAnchor constraintEqualToAnchor:self.superview.topAnchor constant:500];
    topAnchorConstraint.active = YES;
*/
    _heightConstraint = [self.heightAnchor constraintEqualToConstant:300];
    _heightConstraint.active = YES;
    _widthConstraint = [self.widthAnchor constraintEqualToConstant:300];
    _widthConstraint.active = YES;


    // 图标背景
    self.iconBackgroundView = [[UIView alloc] initWithFrame:CGRectMake(_cardContentpadding, _cardContentpadding, 80*_sizeFactor, 80*_sizeFactor)];
    self.iconBackgroundView.backgroundColor = defaultBlue;
    self.iconBackgroundView.layer.cornerRadius = 20*_sizeFactor;
    [self addSubview:self.iconBackgroundView];

    // 图标图片
    self.hostIconView = [[UIImageView alloc] init];
    self.hostIconView.translatesAutoresizingMaskIntoConstraints = NO;
    self.hostIconView.contentMode = UIViewContentModeScaleAspectFit;
    if (@available(iOS 13.0, *)) {
        self.hostIconView.image = [UIImage systemImageNamed:@"display"];
    } else {
        self.hostIconView.image = [UIImage imageNamed:@"Computer"];
        [NSLayoutConstraint activateConstraints:@[
            [self.hostIconView.heightAnchor constraintEqualToConstant:57*_sizeFactor],
            [self.hostIconView.widthAnchor constraintEqualToConstant:57*_sizeFactor],
        ]];
    }
    self.hostIconView.tintColor = [UIColor whiteColor];
    [self.iconBackgroundView addSubview:self.hostIconView];
    [NSLayoutConstraint activateConstraints:@[
        [self.hostIconView.centerXAnchor constraintEqualToAnchor:self.iconBackgroundView.centerXAnchor constant:0],
        [self.hostIconView.centerYAnchor constraintEqualToAnchor:self.iconBackgroundView.centerYAnchor constant:0],
        [self.hostIconView.heightAnchor constraintEqualToConstant:63*_sizeFactor],
        [self.hostIconView.widthAnchor constraintEqualToConstant:63*_sizeFactor],
    ]];
    // [self.iconBackgroundView layoutIfNeeded];
    // [self.iconImageView layoutIfNeeded];

    //spinner
    _hostSpinner = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleWhite];
    _hostSpinner.userInteractionEnabled = NO;
    _hostSpinner.translatesAutoresizingMaskIntoConstraints = NO;
    _hostSpinner.hidesWhenStopped = YES;
    [self.iconBackgroundView addSubview:_hostSpinner];
    [NSLayoutConstraint activateConstraints:@[
        [_hostSpinner.centerXAnchor constraintEqualToAnchor:self.iconBackgroundView.centerXAnchor constant:0],
        [_hostSpinner.centerYAnchor constraintEqualToAnchor:self.iconBackgroundView.centerYAnchor constant:computerIconMonitorCenterYOffset],
    ]];
    _hostSpinner.transform = CGAffineTransformMakeScale(_sizeFactor, _sizeFactor);
    [_hostSpinner stopAnimating];
    // [_hostSpinner startAnimating];

    
    // lockIcon
    lockIconView =[[UIImageView alloc] init];
    lockIconView.translatesAutoresizingMaskIntoConstraints = NO;
    if (@available(iOS 13.0, *)) {
        lockIconView.image = [UIImage systemImageNamed:@"lock.fill"];
    } else {
        // lockIconView.image = [UIImage imageNamed:@"Computer"];
    }
    lockIconView.tintColor = [UIColor whiteColor];
    [self.iconBackgroundView insertSubview:lockIconView aboveSubview:_iconBackgroundView];
    [NSLayoutConstraint activateConstraints:@[
        [lockIconView.centerXAnchor constraintEqualToAnchor:_iconBackgroundView.centerXAnchor constant:0],
        [lockIconView.centerYAnchor constraintEqualToAnchor:_iconBackgroundView.centerYAnchor constant:computerIconMonitorCenterYOffset],
        [lockIconView.widthAnchor constraintEqualToConstant:22*_sizeFactor],
        [lockIconView.heightAnchor constraintEqualToConstant:22*_sizeFactor]
    ]];
    lockIconView.hidden = true;

    // 设备名
    self.hostNameLabel = [[UILabel alloc] initWithFrame:CGRectMake(_cardContentpadding+_iconBackgroundView.frame.size.width+20*_sizeFactor, _cardContentpadding+_iconBackgroundView.frame.size.height/10, 300*_sizeFactor, 30*_sizeFactor)];
    self.hostNameLabel.numberOfLines = 1;
    self.hostNameLabel.lineBreakMode = NSLineBreakByTruncatingTail;

    self.hostIconView.translatesAutoresizingMaskIntoConstraints = NO;
    self.hostNameLabel.text = @"RazerBlade 16";
    self.hostNameLabel.textColor = [UIColor whiteColor]; //theme
    self.hostNameLabel.font = [UIFont boldSystemFontOfSize:20*_sizeFactor];
    [self addSubview:self.hostNameLabel];


    
    // 在线状态图标
    self.statusIcon = [[UIImageView alloc] initWithFrame:CGRectMake(180, 70, 20*_sizeFactor, 20*_sizeFactor)];
    self.statusIcon.contentMode = UIViewContentModeScaleAspectFit;
    self.statusIcon.translatesAutoresizingMaskIntoConstraints = NO;
    if (@available(iOS 13.0, *)) {
        self.statusIcon.image = [UIImage systemImageNamed:@"wifi"];
    } else {
        // Fallback on earlier versions
    }
    self.statusIcon.tintColor = defaultGreen;

    [self addSubview:self.statusIcon];
    [NSLayoutConstraint activateConstraints:@[
        [self.statusIcon.leadingAnchor constraintEqualToAnchor:self.hostNameLabel.leadingAnchor],
        [self.statusIcon.topAnchor constraintEqualToAnchor:self.hostNameLabel.bottomAnchor constant:4*_sizeFactor],
        [self.statusIcon.widthAnchor constraintEqualToConstant:19*_sizeFactor]
    ]];


    // 在线文字
    self.statusLabel = [[UILabel alloc] initWithFrame:CGRectMake(205, 68, 100, 24)];
    self.statusLabel.translatesAutoresizingMaskIntoConstraints = NO;
    self.statusLabel.text = @"Online";
    self.statusLabel.font = [UIFont systemFontOfSize:16*_sizeFactor weight:UIFontWeightMedium];
    self.statusLabel.textColor = defaultGreen;
    // self.statusLabel.font = [UIFont systemFontOfSize:16*_sizeFactor];
    [self addSubview:self.statusLabel];
    [NSLayoutConstraint activateConstraints:@[
        [self.statusLabel.leadingAnchor constraintEqualToAnchor:self.statusIcon.trailingAnchor constant:3*_sizeFactor],
        [self.statusLabel.centerYAnchor constraintEqualToAnchor:self.statusIcon.centerYAnchor constant:0],
    ]];


    // 设置按钮
    /*
    self.settingsButton = [UIButton buttonWithType:UIButtonTypeSystem];
    self.settingsButton.frame = CGRectMake(self.bounds.size.width - 40, 20, 24, 24);
    if (@available(iOS 13.0, *)) {
        [self.settingsButton setImage:[UIImage systemImageNamed:@"gearshape"] forState:UIControlStateNormal];
    } else {
        // Fallback on earlier versions
    }
    self.settingsButton.tintColor = [UIColor lightGrayColor];
    [self addSubview:self.settingsButton];
     */

    // 启动应用按钮
    self.leftButton = [UIButton buttonWithType:UIButtonTypeSystem];
    self.leftButton.translatesAutoresizingMaskIntoConstraints = NO;
    self.leftButton.frame = CGRectMake(20, 200, 150, buttonHeight);
    [self.leftButton setTitle:[LocalizationHelper localizedStringForKey:@"Applications"] forState:UIControlStateNormal];
    [self.leftButton setTitleColor:[UIColor textColorGray] forState:UIControlStateNormal]; //theme
    self.leftButton.titleLabel.font = [UIFont systemFontOfSize:16*_sizeFactor];
    [self addSubview:self.leftButton];
    [NSLayoutConstraint activateConstraints:@[
        [self.leftButton.leadingAnchor constraintEqualToAnchor:self.iconBackgroundView.leadingAnchor constant:0],
        [self.leftButton.topAnchor constraintEqualToAnchor:self.iconBackgroundView.bottomAnchor constant:iconAndButtonSpacing],
        [self.leftButton.widthAnchor constraintEqualToConstant:appButtonWidth],
        [self.leftButton.heightAnchor constraintEqualToConstant:buttonHeight],
        // [self.launchButton.titleLabel.leadingAnchor constraintEqualToAnchor:self.launchButton.imageView.trailingAnchor constant:3*_sizeFactor]
    ]];
    

    // 开始串流按钮
    self.rightButton = [UIButton buttonWithType:UIButtonTypeSystem];
    self.rightButton.translatesAutoresizingMaskIntoConstraints = NO;
    self.rightButton.frame = CGRectMake(0, 0, 150, 50);
    self.rightButton.backgroundColor = defaultBlue;
    self.rightButton.layer.cornerRadius = 10;
    [self.rightButton setTitle:[LocalizationHelper localizedStringForKey:@"  Launch"] forState:UIControlStateNormal];
    [self.rightButton setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal]; // theme
    self.rightButton.titleLabel.font = [UIFont boldSystemFontOfSize:16*_sizeFactor];

    // self.launchButton.imageEdgeInsets = UIEdgeInsetsMake(0, -10, 0, 0);
    self.rightButton.tintColor = [UIColor whiteColor];
    [self addSubview:self.rightButton];
    if (@available(iOS 13.0, *)) {
        UIImageSymbolConfiguration *config = [UIImageSymbolConfiguration configurationWithPointSize:self.rightButton.frame.size.height/4*_sizeFactor];
        [self.rightButton setImage:[UIImage systemImageNamed:@"play.fill" withConfiguration:config] forState:UIControlStateNormal];

    } else {
        // Fallback on earlier versions
    }
    
    [_rightButton addTarget:self action:@selector(buttonTapped) forControlEvents:UIControlEventTouchUpInside];
    
    
    [NSLayoutConstraint activateConstraints:@[
        [self.rightButton.leadingAnchor constraintEqualToAnchor:self.leftButton.trailingAnchor constant:15*_sizeFactor],
        [self.rightButton.centerYAnchor constraintEqualToAnchor:self.leftButton.centerYAnchor constant:0],
        [self.rightButton.widthAnchor constraintEqualToConstant:launchButtonWidth],
        [self.rightButton.heightAnchor constraintEqualToConstant:buttonHeight],
        // [self.launchButton.titleLabel.leadingAnchor constraintEqualToAnchor:self.launchButton.imageView.trailingAnchor constant:3*_sizeFactor]
    ]];
    
    // 配对按钮
    self.pairButton = [UIButton buttonWithType:UIButtonTypeSystem];
    self.pairButton.translatesAutoresizingMaskIntoConstraints = NO;
    self.pairButton.frame = CGRectMake(0, 0, 150, 50);
    self.pairButton.backgroundColor = [UIColor appPrimaryColorWithAlpha];
    self.pairButton.layer.cornerRadius = 10;
    [self.pairButton setTitle:[LocalizationHelper localizedStringForKey:@"  Pair with PIN"] forState:UIControlStateNormal];
    [self.pairButton setTitleColor:defaultBlue forState:UIControlStateNormal]; // theme
    self.pairButton.titleLabel.font = [UIFont boldSystemFontOfSize:16*_sizeFactor];
    [self addSubview:self.pairButton];
    
    // self.launchButton.imageEdgeInsets = UIEdgeInsetsMake(0, -10, 0, 0);
    if (@available(iOS 13.0, *)) {
        UIImageSymbolConfiguration *config = [UIImageSymbolConfiguration configurationWithPointSize:self.pairButton.frame.size.height/3.5*_sizeFactor weight:UIImageSymbolWeightBold];
        UIImage *templateImage = [UIImage systemImageNamed:@"lock.open.fill" withConfiguration:config];
        UIImage *coloredImage = [templateImage imageWithTintColor:defaultBlue renderingMode:UIImageRenderingModeAlwaysOriginal];
        [self.pairButton setImage:coloredImage forState:UIControlStateNormal];
    } else {
        // Fallback on earlier versions
    }
    _pairButton.backgroundColor = [UIColor appPrimaryColorWithAlpha];
    [_pairButton setTitleColor:defaultBlue forState:UIControlStateNormal]; // theme

    [NSLayoutConstraint activateConstraints:@[
        [self.pairButton.leadingAnchor constraintEqualToAnchor:self.leadingAnchor constant:_cardContentpadding],
        [self.pairButton.trailingAnchor constraintEqualToAnchor:self.trailingAnchor constant:-_cardContentpadding],
        [self.pairButton.topAnchor constraintEqualToAnchor:self.iconBackgroundView.bottomAnchor constant:iconAndButtonSpacing],
        // [self.pairButton.widthAnchor constraintEqualToConstant:launchButtonWidth],
        [self.pairButton.heightAnchor constraintEqualToConstant:buttonHeight],
    ]];

    
    //分隔线
    _separatorLine = [[UIView alloc] init];
    _separatorLine.backgroundColor = [UIColor colorWithWhite:0.3 alpha:5.0];
    _separatorLine.translatesAutoresizingMaskIntoConstraints = NO;
    [self addSubview:_separatorLine];
    [NSLayoutConstraint activateConstraints:@[
        [_separatorLine.leadingAnchor constraintEqualToAnchor:self.leadingAnchor constant:_cardContentpadding],
        [_separatorLine.trailingAnchor constraintEqualToAnchor:self.trailingAnchor constant:-_cardContentpadding],
        [_separatorLine.centerYAnchor constraintEqualToAnchor:_iconBackgroundView.bottomAnchor constant: iconAndButtonSpacing/2],
        [_separatorLine.heightAnchor constraintEqualToConstant:1.0/UIScreen.mainScreen.scale]
        // [self.launchButton.titleLabel.leadingAnchor constraintEqualToAnchor:self.launchButton.imageView.trailingAnchor constant:3*_sizeFactor]
    ]];


    // [self layoutSubviews];
    // [self layoutIfNeeded];
    
    _widthConstraint.constant = _cardContentpadding*2 + appButtonWidth + 15*_sizeFactor + launchButtonWidth;
    _heightConstraint.constant = _cardContentpadding*2 + _iconBackgroundView.frame.size.height + iconAndButtonSpacing + buttonHeight + 1;
    
    _size = CGSizeMake(_widthConstraint.constant, _heightConstraint.constant);
    // standard size: 261 * 184
    
    [self updateTheme:_userIterfaceStyle];
    // [self updateContentsForHost:_host];
    // [self updateTheme:UIUserInterfaceStyleLight];
}

- (void)createBackgroundLayer{
    backgroundLayer = [CAGradientLayer layer];
    UIColor *gradientColorDark = [UIColor colorWithRed:0.0 green:0.319 blue:0.64 alpha:1.0];
    UIColor *gradientColorLight = [gradientColorDark colorWithAlphaComponent:0.52];
    CGColorRef gradientColorRef = _userIterfaceStyle == UIUserInterfaceStyleDark ? gradientColorDark.CGColor : gradientColorLight.CGColor;
    backgroundLayer.colors = @[
        (__bridge id)[UIColor clearColor].CGColor,
        (__bridge id)[UIColor clearColor].CGColor,
        (__bridge id)[UIColor clearColor].CGColor,
        (__bridge id)gradientColorRef
    ];

    backgroundLayer.locations = @[@0, @0.18, @0.5, @1];
    backgroundLayer.startPoint = CGPointMake(0.25, 0.5);
    backgroundLayer.endPoint = CGPointMake(0.75, 0.5);

    CGAffineTransform transform = CGAffineTransformMake(-1.01, -1, 1, -3.67, 0.5, 2.83);
    backgroundLayer.transform = CATransform3DMakeAffineTransform(transform);
    [self.layer insertSublayer:backgroundLayer atIndex:0];
}

- (void)layoutSubviews {
    [super layoutSubviews];
    backgroundLayer.bounds = CGRectInset(self.bounds, -0.5 * self.bounds.size.width, -0.5 * self.bounds.size.height);
    backgroundLayer.position = CGPointMake(CGRectGetMidX(self.bounds), CGRectGetMidY(self.bounds));
    [self updateContentsForHost:_host]; // quick update before looping
}


- (void)updateTheme:(UIUserInterfaceStyle)userIterfaceStyle{
    switch (userIterfaceStyle) {
        case UIUserInterfaceStyleDark:
            _hostNameLabel.textColor = [UIColor textColorDark];
            [_leftButton setTitleColor:[UIColor appPrimaryColor] forState:UIControlStateNormal];
            _separatorLine.backgroundColor = [UIColor separatorColorDark];
            // [_rightButton setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
            self.backgroundColor = [UIColor widgetBackgroundColorDark];
            backgroundLayer.hidden = NO;
            break;
        case UIUserInterfaceStyleLight:
            _hostNameLabel.textColor = [UIColor textColorLight];
            [_leftButton setTitleColor:[UIColor appPrimaryColor] forState:UIControlStateNormal];
            _separatorLine.backgroundColor = [UIColor separatorColorLight];
            // [_rightButton setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
            self.backgroundColor = [UIColor widgetBackgroundColorLight];
            backgroundLayer.hidden = NO;
            break;
        default:break;
    }
    [self updateContentsForHost:_host];
}


- (void)didMoveToSuperview {
    // Start our update loop when we are added to our cell
    if (self.superview != nil && _host != nil) {
        NSLog(@"start update loop");
        [self updateLoop];
    }
}

- (void)traitCollectionDidChange:(UITraitCollection *)previousTraitCollection {
    [super traitCollectionDidChange:previousTraitCollection];

    if (@available(iOS 13.0, *)) {
        if ([self.traitCollection hasDifferentColorAppearanceComparedToTraitCollection:previousTraitCollection]) {
            [self updateTheme:self.traitCollection.userInterfaceStyle];
        }
    } else {
        [self updateTheme:UIUserInterfaceStyleDark];
    }
}


- (void) buttonTapped {
    NSLog(@"button test");
}


- (void) updateLoop {
    // Stop immediately if the view has been detached
    if (self.superview == nil) {
        return;
    }
        
    [self updateContentsForHost:_host];
    
    // Queue the next refresh cycle
    [self performSelector:@selector(updateLoop) withObject:self afterDelay:REFRESH_CYCLE];
}

- (void) updateContentsForHost:(TemporaryHost*)host {
    _hostNameLabel.text = host.name;
    // self.hostNameLabel.text = @"RazerBlade 16 testttttettest";

    
    backgroundLayer.hidden = !(host.state == StateOnline && host.pairState == PairStatePaired);

    
    
    switch (host.state) {
        case StateOnline:
            [_hostSpinner stopAnimating];
            _statusLabel.textColor = defaultGreen;
            _statusLabel.text = @"Online";
            _statusIcon.tintColor = defaultGreen;
            
            if (@available(iOS 13.0, *)) {
                _statusIcon.image = [UIImage systemImageNamed:@"wifi"];
            } else {
                // Fallback on earlier versions
            }
            _hostIconView.tintColor = [UIColor whiteColor];

            

            if(host.pairState == PairStatePaired){
                _iconBackgroundView.backgroundColor = defaultBlue;
                lockIconView.hidden = YES;
                [_leftButton setTitle:[LocalizationHelper localizedStringForKey:@"Applications"] forState:UIControlStateNormal];
                [_rightButton setTitle:[LocalizationHelper localizedStringForKey:@"  Launch"] forState:UIControlStateNormal];
                [_leftButton setEnabled:YES];
                [_rightButton setEnabled:YES];
                _leftButton.hidden = NO;
                _rightButton.hidden = NO;
                _pairButton.hidden = YES;

                [_leftButton setTitleColor:defaultBlue forState:UIControlStateNormal]; // theme
                if (@available(iOS 13.0, *)) {
                    UIImageSymbolConfiguration *config = [UIImageSymbolConfiguration configurationWithPointSize:self.rightButton.frame.size.height/4*_sizeFactor];
                    [self.rightButton setImage:[UIImage systemImageNamed:@"play.fill" withConfiguration:config] forState:UIControlStateNormal];
                } else {
                    // Fallback on earlier versions
                }
                _rightButton.backgroundColor = defaultBlue;
                [_rightButton setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal]; // theme
            }
            else {
                _iconBackgroundView.backgroundColor = [UIColor appPrimaryColorWithAlpha];
                lockIconView.hidden = NO;
                [_leftButton setTitle:[LocalizationHelper localizedStringForKey:@"Applications"] forState:UIControlStateNormal];
                [_rightButton setTitle:[LocalizationHelper localizedStringForKey:@"  Launch"] forState:UIControlStateNormal];
                [_leftButton setEnabled:YES];
                [_rightButton setEnabled:YES];
                _leftButton.hidden = YES;
                _rightButton.hidden = YES;
                _pairButton.hidden = NO;



                [_leftButton setTitleColor:defaultBlue forState:UIControlStateNormal]; // theme
                if (@available(iOS 13.0, *)) {
                    UIImageSymbolConfiguration *config = [UIImageSymbolConfiguration configurationWithPointSize:self.rightButton.frame.size.height/4*_sizeFactor];
                    [self.rightButton setImage:[UIImage systemImageNamed:@"play.fill" withConfiguration:config] forState:UIControlStateNormal];
                } else {
                    // Fallback on earlier versions
                }
                _rightButton.backgroundColor = [UIColor appPrimaryColorWithAlpha];
                [_rightButton setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal]; // theme
            }
            

            break;
        case StateOffline:
            [_hostSpinner stopAnimating];
            // _iconBackgroundView.backgroundColor = _userIterfaceStyle == UIUserInterfaceStyleDark ? [UIColor appBackgroundColorDark] : [UIColor appBackgroundColorLight];
            _iconBackgroundView.backgroundColor = _userIterfaceStyle == UIUserInterfaceStyleDark ? [UIColor appBackgroundColorDark] : [UIColor appBackgroundColorLight];
            _statusLabel.textColor = [UIColor textColorGray];
            _statusLabel.text = @"Offline";
            _statusIcon.tintColor = [UIColor textColorGray];
            if (@available(iOS 13.0, *)) {
                _statusIcon.image = [UIImage systemImageNamed:@"exclamationmark.triangle.fill"];
            } else {
                // Fallback on earlier versions
            }
            _hostIconView.tintColor = [UIColor lowProfileGray];
            lockIconView.hidden = YES;
            [_leftButton setTitle:[LocalizationHelper localizedStringForKey:@"Test network"] forState:UIControlStateNormal];
            [_rightButton setTitle:[LocalizationHelper localizedStringForKey:@"  Wakeup"] forState:UIControlStateNormal];
            [_leftButton setEnabled:YES];
            [_rightButton setEnabled:YES];
            _leftButton.hidden = NO;
            _rightButton.hidden = NO;
            _pairButton.hidden = YES;


            [_leftButton setTitleColor:defaultBlue forState:UIControlStateNormal]; // theme
            if (@available(iOS 13.0, *)) {
                UIImageSymbolConfiguration *config = [UIImageSymbolConfiguration configurationWithPointSize:self.rightButton.frame.size.height/3.5*_sizeFactor weight:UIImageSymbolWeightBold];
                UIImage *templateImage = [UIImage systemImageNamed:@"power" withConfiguration:config];
                UIImage *coloredImage = [templateImage imageWithTintColor:defaultBlue renderingMode:UIImageRenderingModeAlwaysOriginal];
                [self.rightButton setImage:coloredImage forState:UIControlStateNormal];
            } else {
                // Fallback on earlier versions
            }
            _rightButton.backgroundColor = [UIColor appPrimaryColorWithAlpha];
            [_rightButton setTitleColor:defaultBlue forState:UIControlStateNormal]; // theme

            break;
        case StateUnknown:
            _hostSpinner.color = [UIColor whiteColor];
            [_hostSpinner startAnimating];
            // _iconBackgroundView.backgroundColor = _userIterfaceStyle == UIUserInterfaceStyleDark ? [UIColor appBackgroundColorDark] : [UIColor appBackgroundColorLight];
            _iconBackgroundView.backgroundColor = [UIColor appPrimaryColorWithAlpha];
            _statusLabel.textColor = [UIColor textColorGray];
            _statusLabel.text = @"Detecting...";
            _statusIcon.tintColor = [UIColor textColorGray];
            if (@available(iOS 13.0, *)) {
                _statusIcon.image = [UIImage systemImageNamed:@"antenna.radiowaves.left.and.right"];
            } else {
                // Fallback on earlier versions
            }
            // _hostIconView.tintColor = [UIColor lowProfileGray];
            _hostIconView.tintColor = defaultBlue;
            lockIconView.hidden = YES;
            [_leftButton setTitle:[LocalizationHelper localizedStringForKey:@"Test network"] forState:UIControlStateNormal];
            [_rightButton setTitle:[LocalizationHelper localizedStringForKey:@"  Wakeup"] forState:UIControlStateNormal];
            [_leftButton setEnabled:NO];
            [_rightButton setEnabled:NO];
            _leftButton.hidden = NO;
            _rightButton.hidden = NO;
            _pairButton.hidden = YES;

            
            [_leftButton setTitleColor:[UIColor textColorGray] forState:UIControlStateNormal]; // theme
            if (@available(iOS 13.0, *)) {
                UIImageSymbolConfiguration *config = [UIImageSymbolConfiguration configurationWithPointSize:self.rightButton.frame.size.height/3.5*_sizeFactor weight:UIImageSymbolWeightBold];
                UIImage *templateImage = [UIImage systemImageNamed:@"power" withConfiguration:config];
                UIImage *coloredImage = [templateImage imageWithTintColor:[UIColor textColorGray] renderingMode:UIImageRenderingModeAlwaysOriginal];
                [self.rightButton setImage:coloredImage forState:UIControlStateNormal];
            } else {
                // Fallback on earlier versions
            }
            _rightButton.backgroundColor = [[UIColor textColorGray] colorWithAlphaComponent:0.2];
            [_rightButton setTitleColor:[UIColor textColorGray] forState:UIControlStateNormal]; // theme


            break;
        default:break;
    }
    
    /*
    if (host.state == StateOnline) {
        [_hostSpinner stopAnimating];

        lockIconView.hidden = ! (host.pairState == PairStateUnpaired);
        
        
        if (host.pairState == PairStateUnpaired) {
            
        }
        else {
        }
        
    }
    else if (host.state == StateOffline) {
        [_hostSpinner stopAnimating];
    }
    else {
        [_hostSpinner startAnimating];
    }
     */
}



@end
