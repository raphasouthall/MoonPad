//
//  HostCollectionViewController.m
//  Moonlight-ZWM
//
//  Created by True砖家 on 2025/5/28.
//  Copyright 2025 True砖家 @ Bilibili. All rights reserved.
//

#import "HostCollectionViewController.h"
#import "HostCardView.h"
#import "TemporaryHost.h"
#import "UIColor+Theme.h"



@implementation HostCell

- (void)prepareForReuse {
    [super prepareForReuse];
    [self.cardView removeFromSuperview];
    self.cardView = nil;
}

- (CGFloat)getHostCardSizeFactor{
    TemporaryHost* dummyHost = [[TemporaryHost alloc] init];
    HostCardView* dummyCard = [[HostCardView alloc] initWithHost:dummyHost];
    return self.contentView.bounds.size.height/dummyCard.size.height;
}


- (void)configureWithHost:(TemporaryHost *)host {
    if (!self.cardView) {
        self.cardView = [[HostCardView alloc] initWithHost:host andSizeFactor:[self getHostCardSizeFactor]];
        // self.cardView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
        [self.contentView addSubview:self.cardView];
        NSLog(@"contentView width %f, %f", self.contentView.bounds.size.width, self.cardView.size.width);

        [NSLayoutConstraint activateConstraints:@[
            [self.cardView.leadingAnchor constraintEqualToAnchor:self.contentView.leadingAnchor],
            [self.cardView.topAnchor constraintEqualToAnchor:self.contentView.topAnchor],
        ]];
    }
}

@end

@interface HostCollectionViewController () <UICollectionViewDelegateFlowLayout>
@property (nonatomic, strong, readwrite) NSMutableArray<TemporaryHost *> *items;
@property (nonatomic, strong) NSLayoutConstraint *collectionViewHeightConstraint;
@end

@implementation HostCollectionViewController

- (instancetype)init {
    UICollectionViewFlowLayout *layout = [[UICollectionViewFlowLayout alloc] init];
    layout.sectionInset = UIEdgeInsetsMake(0, 0, 0, 13); // 上、左、下、右的间距
    if (self = [super initWithCollectionViewLayout:layout]) {
        _interItemMinimumSpacing = 10;
        _minimumLineSpacing = 10;
        // _cellSize = CGSizeMake(100, 100);
        _items = [NSMutableArray array];

        _collectionViewHeightConstraint = [self.collectionView.heightAnchor constraintEqualToConstant:50];
        _collectionViewHeightConstraint.active = YES;
    }
    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    [self.collectionView registerClass:[HostCell class] forCellWithReuseIdentifier:@"HostCell"];
    if (@available(iOS 13.0, *)) {
        self.collectionView.backgroundColor = UIColor.systemBackgroundColor;
    } else {
        // Fallback on earlier versions
    }
    self.collectionView.alwaysBounceVertical = NO;
    self.collectionView.backgroundColor = self.view.traitCollection.userInterfaceStyle == UIUserInterfaceStyleDark ? [UIColor appBackgroundColorDark] : [UIColor appBackgroundColorLight];
}

#pragma mark - Data control

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    NSLog(@"View did appear");
}

- (void)didMoveToParentViewController:(UIViewController *)parent {
    [super didMoveToParentViewController:parent];
    NSLog(@"moved to parentVC: %@", parent);
    
    // 可以在这里进行一些初始化，比如加载数据、刷新 UI 等
}

- (void)addHost:(TemporaryHost *)host {
    if(![self.items containsObject:host]){
        [self.items addObject:host];
        [self.items addObject:host];
        [self.items addObject:host];
        [self.items addObject:host];

        [self.collectionView reloadData];
        // [self.view layoutIfNeeded];
    }
    NSLog(@"addhost log");

}

- (void)removeLastItem {
    if (self.items.count > 0) {
        [self.items removeLastObject];
        [self.collectionView reloadData];
    }
}

- (void)viewDidLayoutSubviews {
    [super viewDidLayoutSubviews];
    
    CGFloat contentHeight = self.collectionView.collectionViewLayout.collectionViewContentSize.height;
    bool contentExceedsView = contentHeight > self.view.superview.bounds.size.height - self.view.frame.origin.y;
    if(contentExceedsView){
        [NSLayoutConstraint activateConstraints:@[
            [self.view.bottomAnchor constraintEqualToAnchor:self.view.superview.safeAreaLayoutGuide.bottomAnchor constant:0]
        ]];
    }
    else _collectionViewHeightConstraint.constant = contentHeight;
}

#pragma mark - UICollectionView DataSource

- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section {
    return self.items.count;
}

- (__kindof UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath {
    NSLog(@"config cell log");

    HostCell *cell = [collectionView dequeueReusableCellWithReuseIdentifier:@"HostCell" forIndexPath:indexPath];
    TemporaryHost *host = self.items[indexPath.item];
    [cell configureWithHost:host];
    return cell;
}

#pragma mark - UICollectionViewDelegateFlowLayout

- (CGSize)collectionView:(UICollectionView *)collectionView
                  layout:(UICollectionViewLayout *)collectionViewLayout
  sizeForItemAtIndexPath:(NSIndexPath *)indexPath {
    NSLog(@"return cellsize: %f, %f", self.cellSize.width, self.cellSize.height);
    return self.cellSize;
}

- (CGFloat)collectionView:(UICollectionView *)collectionView
                   layout:(UICollectionViewLayout *)collectionViewLayout
minimumInteritemSpacingForSectionAtIndex:(NSInteger)section {
    NSLog(@"return iterIterm: %f", self.interItemMinimumSpacing);

    return self.interItemMinimumSpacing;
}

- (CGFloat)collectionView:(UICollectionView *)collectionView
                   layout:(UICollectionViewLayout *)collectionViewLayout
minimumLineSpacingForSectionAtIndex:(NSInteger)section {
    return self.minimumLineSpacing;
}

@end
