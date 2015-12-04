//
//  YSLContainerViewController.m
//  YSLContainerViewController
//
//  Created by yamaguchi on 2015/02/10.
//  Copyright (c) 2015年 h.yamaguchi. All rights reserved.
//

#import "YSLContainerViewController.h"
#import "YSLScrollMenuView.h"

static const CGFloat kYSLScrollMenuViewHeight = 40;

@interface YSLContainerViewController () <UIScrollViewDelegate, YSLScrollMenuViewDelegate>

@property (nonatomic, assign) CGFloat topBarHeight;
@property (nonatomic, strong) NSArray *itemSizes;
@property (nonatomic, assign) NSInteger currentIndex;
@property (nonatomic, assign) NSInteger initialIndex;
@property (nonatomic, strong) YSLScrollMenuView *menuView;

@end

@implementation YSLContainerViewController

- (id)initWithControllers:(NSArray *)controllers
             initialIndex:(int)index
                positions:(NSArray *)sizes
             topBarHeight:(CGFloat)topBarHeight
     parentViewController:(UIViewController *)parentViewController;
{
    self = [super init];
    if (self) {
        
        [parentViewController addChildViewController:self];
        [self didMoveToParentViewController:parentViewController];
        
        _currentIndex = -1;
        _topBarHeight = topBarHeight;
        _titles = [[NSMutableArray alloc] init];
        _childControllers = [[NSMutableArray alloc] init];
        _childControllers = [controllers mutableCopy];
        _itemSizes = sizes.copy;
        _initialIndex = index;
        NSMutableArray *titles = [NSMutableArray array];
        for (UIViewController *vc in _childControllers) {
            [titles addObject:[vc valueForKey:@"title"]];
        }
        _titles = [titles mutableCopy];
    }
    return self;
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    // setupViews
    UIView *viewCover = [[UIView alloc]init];
    [self.view addSubview:viewCover];
    
    CGRect selfFrame = self.view.frame;
    CGRect csvFrame = CGRectMake(0, _topBarHeight + kYSLScrollMenuViewHeight, selfFrame.size.width, selfFrame.size.height - (_topBarHeight + kYSLScrollMenuViewHeight));
    //CGFloat screen_w = SCREEN_WIDTH;
    
    // ContentScrollview setup
    _contentScrollView = [[UIScrollView alloc]init];
    _contentScrollView.frame = csvFrame;
    _contentScrollView.backgroundColor = [UIColor colorWithWhite:1.f alpha:0.7f];
    _contentScrollView.pagingEnabled = YES;
    _contentScrollView.delegate = self;
    _contentScrollView.showsHorizontalScrollIndicator = NO;
    _contentScrollView.scrollsToTop = NO;
    [self.view addSubview:_contentScrollView];
    _contentScrollView.contentSize = CGSizeMake(csvFrame.size.width * self.childControllers.count, csvFrame.size.height);
    
    // ContentViewController setup
    //NSArray* vv = @[ [UIColor redColor], [UIColor blueColor] ];
    for (int i = 0; i < self.childControllers.count; i++) {
        id obj = [self.childControllers objectAtIndex:i];
        if ([obj isKindOfClass:[UIViewController class]]) {
            UIViewController *controller = (UIViewController*)obj;
            CGFloat scrollWidth = csvFrame.size.width;
            CGFloat scrollHeght = csvFrame.size.height;
            controller.view.frame = CGRectMake(i * scrollWidth, 0, scrollWidth, scrollHeght);
            [_contentScrollView addSubview:controller.view];
            //controller.view.backgroundColor = [vv objectAtIndex:i%2];
        }
    }
    // meunView
    _menuView = [[YSLScrollMenuView alloc]initWithFrame:CGRectMake(0, _topBarHeight, selfFrame.size.width, kYSLScrollMenuViewHeight)];
    _menuView.backgroundColor = [UIColor clearColor];
    _menuView.delegate = self;
    _menuView.viewbackgroudColor = self.menuBackGroudColor;
    _menuView.itemfont = self.menuItemFont;
    _menuView.itemTitleColor = self.menuItemTitleColor;
    _menuView.itemIndicatorColor = self.menuIndicatorColor;
    _menuView.scrollView.scrollsToTop = NO;
    [_menuView setItemTitleArray:self.titles];
    [_menuView setItemSizeArray:self.itemSizes];
    [self.view addSubview:_menuView];
    [_menuView setShadowView];
    
    [self scrollMenuViewSelectedIndex:self.initialIndex];
}

#pragma mark -- private

- (void)setChildViewControllerWithCurrentIndex:(NSInteger)currentIndex
{
    for (int i = 0; i < self.childControllers.count; i++) {
        id obj = self.childControllers[i];
        if ([obj isKindOfClass:[UIViewController class]]) {
            UIViewController *controller = (UIViewController*)obj;
            if (i == currentIndex) {
                [controller willMoveToParentViewController:self];
                [self addChildViewController:controller];
                [controller didMoveToParentViewController:self];
            } else {
                [controller willMoveToParentViewController:self];
                [controller removeFromParentViewController];
                [controller didMoveToParentViewController:self];
            }
        }
    }
}
#pragma mark -- YSLScrollMenuView Delegate

- (void)scrollMenuViewSelectedIndex:(NSInteger)index
{
    BOOL isAnimated = YES;
    [_contentScrollView setContentOffset:CGPointMake(index * _contentScrollView.frame.size.width, 0.) animated:isAnimated];
    
    // item color will be set after scrolling
    if(!isAnimated){
        [_menuView setItemTextColor:self.menuItemTitleColor
           seletedItemTextColor:self.menuItemSelectedTitleColor
                   currentIndex:index];
    }
    
    [self setChildViewControllerWithCurrentIndex:index];
    
    if (index == self.currentIndex) { [self.delegate containerViewShouldHide]; return;}
    self.currentIndex = index;
    [self scrollViewDidScroll:_contentScrollView];
    
    if (self.delegate && [self.delegate respondsToSelector:@selector(containerViewItemIndex:currentController:)]) {
        [self.delegate containerViewItemIndex:self.currentIndex currentController:_childControllers[self.currentIndex]];
    }
}

#pragma mark -- ScrollView Delegate

- (void)scrollViewDidScroll:(UIScrollView *)scrollView
{
    if(self.currentIndex < 0){
        return;
    }
    [_menuView setIndicatorViewFrameWithRatio:1.0 toIndex:self.currentIndex];
//    CGFloat oldPointX = self.currentIndex * scrollView.frame.size.width;
//    CGFloat ratio = (scrollView.contentOffset.x - oldPointX) / scrollView.frame.size.width;
//    
//    CGFloat curPointX = _contentScrollView.contentOffset.x;
//    BOOL isToNextItem = (curPointX > oldPointX);
//    NSInteger targetIndex = (isToNextItem) ? (self.currentIndex + 1) : (self.currentIndex - 1);
//    
//    CGFloat nextItemOffsetX = 1.0f;
//    CGFloat currentItemOffsetX = 1.0f;
//    
//    targetIndex = MAX(0, MIN(targetIndex, self.childControllers.count - 1));
//    nextItemOffsetX = [self.itemSizes[targetIndex] CGPointValue].x;??? objectAtIndex 0
//    currentItemOffsetX = [self.itemSizes[self.currentIndex>=0?:targetIndex] CGPointValue].x;!!! objectAtIndex
//
//    if (targetIndex >= 0 && targetIndex < self.childControllers.count) {
//        // MenuView Move
//        CGFloat indicatorUpdateRatio = ratio;
//        if (isToNextItem) {
//            
//            indicatorUpdateRatio = indicatorUpdateRatio * 1;
//            [_menuView setIndicatorViewFrameWithRatio:indicatorUpdateRatio isNextItem:isToNextItem toIndex:self.currentIndex];
//        } else {
//            
//            indicatorUpdateRatio = indicatorUpdateRatio * -1;
//            [_menuView setIndicatorViewFrameWithRatio:indicatorUpdateRatio isNextItem:isToNextItem toIndex:targetIndex];
//        }
//    }
}

- (void)scrollViewDidEndDecelerating:(UIScrollView *)scrollView
{
    int currentIndex = scrollView.contentOffset.x / _contentScrollView.frame.size.width;
    
    if (currentIndex == self.currentIndex) { return; }
    self.currentIndex = currentIndex;
    
    
    // item color
    [_menuView setItemTextColor:self.menuItemTitleColor
           seletedItemTextColor:self.menuItemSelectedTitleColor
                   currentIndex:currentIndex];
    
    if (self.delegate && [self.delegate respondsToSelector:@selector(containerViewItemIndex:currentController:)]) {
        [self.delegate containerViewItemIndex:self.currentIndex currentController:_childControllers[self.currentIndex]];
    }
    [self setChildViewControllerWithCurrentIndex:self.currentIndex];
}

@end
