//
//  LaunchIntroductionView.m
//  APPLaunchIntroduction
//
//  Created by qq on 2017/9/13.
//  Copyright © 2017年 fangxian. All rights reserved.
//

#import "LaunchIntroductionView.h"

static NSString *const kAppVersion = @"appVersion";
@interface LaunchIntroductionView ()<UIScrollViewDelegate>
{
    UIScrollView  *launchScrollView;
    UIPageControl *page;
}

@end

@implementation LaunchIntroductionView

NSArray *images;
BOOL isScrollOut;//在最后一页再次滑动是否隐藏引导页
BOOL showPageControl; // 是否显示展示PageControl
CGRect enterBtnFrame;
NSString *enterBtnImage;
static LaunchIntroductionView *launch = nil;
NSString *storyboard;

#pragma mark - 创建对象-->>不带button
+(instancetype)sharedWithImages:(NSArray *) imageNames isNeedPageControl:(BOOL )needPageControl{
    showPageControl = needPageControl;
    images = imageNames;
    isScrollOut = YES;
    launch = [[LaunchIntroductionView alloc] initWithFrame:CGRectMake(0, 0, LScreen_width, LScreen_height)];
    launch.backgroundColor = [UIColor whiteColor];
    return launch;
}
#pragma mark - 创建对象-->>带button
+(instancetype)sharedWithImages:(NSArray *)imageNames isNeedPageControl:(BOOL )needPageControl buttonImage:(NSString *)buttonImageName buttonFrame:(CGRect)frame{
    showPageControl = needPageControl;
    images = imageNames;
    isScrollOut = NO;
    enterBtnFrame = frame;
    enterBtnImage = buttonImageName;
    launch = [[LaunchIntroductionView alloc] initWithFrame:CGRectMake(0, 0, LScreen_width, LScreen_height)];
    launch.backgroundColor = [UIColor whiteColor];
    return launch;
}
#pragma mark - 用storyboard创建的项目时调用，不带button
+ (instancetype)sharedWithStoryboardName:(NSString *)storyboardName images:(NSArray *)imageNames isNeedPageControl:(BOOL )needPageControl {
    showPageControl = needPageControl;
    images = imageNames;
    storyboard = storyboardName;
    isScrollOut = YES;
    launch = [[LaunchIntroductionView alloc] initWithFrame:CGRectMake(0, 0, LScreen_width, LScreen_height)];
    launch.backgroundColor = [UIColor whiteColor];
    return launch;
}
#pragma mark - 用storyboard创建的项目时调用，带button
+ (instancetype)sharedWithStoryboard:(NSString *)storyboardName images:(NSArray *)imageNames isNeedPageControl:(BOOL )needPageControl buttonImage:(NSString *)buttonImageName buttonFrame:(CGRect)frame{
    showPageControl = needPageControl;
    images = imageNames;
    isScrollOut = NO;
    enterBtnFrame = frame;
    storyboard = storyboardName;
    enterBtnImage = buttonImageName;
    launch = [[LaunchIntroductionView alloc] initWithFrame:CGRectMake(0, 0, LScreen_width, LScreen_height)];
    launch.backgroundColor = [UIColor whiteColor];
    return launch;
}
#pragma mark - 初始化
- (instancetype)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        if ([self isFirstLauch]) {
            UIStoryboard *story;
            if (storyboard) {
                story = [UIStoryboard storyboardWithName:storyboard bundle:nil];
            }
            UIWindow *window = [UIApplication sharedApplication].windows.lastObject;
            if (story) {
                UIViewController * vc = story.instantiateInitialViewController;
                window.rootViewController = vc;
                [vc.view addSubview:self];
            }else {
                [window addSubview:self];
            }
            [self addImages];
        }else{
            [self removeFromSuperview];
        }
    }
    return self;
}
#pragma mark - 判断是不是首次登录或者版本更新
-(BOOL )isFirstLauch{
    //获取当前版本号
    NSDictionary *infoDic = [[NSBundle mainBundle] infoDictionary];
    NSString *currentAppVersion = infoDic[@"CFBundleShortVersionString"];
    //获取上次启动应用保存的appVersion
    NSString *version = [[NSUserDefaults standardUserDefaults] objectForKey:kAppVersion];
    //版本升级或首次登录
    if (version == nil || ![version isEqualToString:currentAppVersion]) {
        [[NSUserDefaults standardUserDefaults] setObject:currentAppVersion forKey:kAppVersion];
        [[NSUserDefaults standardUserDefaults] synchronize];
        return YES;
    }else{
        return NO;
    }
}
#pragma mark - 添加引导页图片
-(void)addImages{
    [self createScrollView];
}
#pragma mark - 创建滚动视图
-(void)createScrollView{
    launchScrollView = [[UIScrollView alloc] initWithFrame:CGRectMake(0, 0, LScreen_width, LScreen_height)];
    launchScrollView.showsHorizontalScrollIndicator = NO;
    launchScrollView.bounces = NO;
    launchScrollView.pagingEnabled = YES;
    launchScrollView.delegate = self;
    launchScrollView.contentSize = CGSizeMake(LScreen_width * images.count, LScreen_height);
    [self addSubview:launchScrollView];
    
    // GCD的快速迭代方法
    dispatch_queue_t queue = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, 2); //优先级 设高点吧!
    dispatch_apply(images.count, queue, ^(size_t index) {
        UIImageView *imageView = [[UIImageView alloc] initWithFrame:CGRectMake(index * LScreen_width, 0, LScreen_width, LScreen_height)];
        imageView.image = [UIImage imageNamed:images[index]];
        //判断要不要添加消失事件
        if (index == images.count - 1 && isScrollOut) {
            NSLog(@"添加消失事件enterBtnClick");
            imageView.userInteractionEnabled = YES;
            [imageView addGestureRecognizer:[[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(tapEnterClick)]];
        }
        [launchScrollView addSubview:imageView];
    });
    
    if (showPageControl) {
        page = [[UIPageControl alloc] initWithFrame:CGRectMake(0, LScreen_height - 50, LScreen_width, 30)];
        page.numberOfPages = images.count;
        page.backgroundColor = [UIColor clearColor];
        page.currentPage = 0;
        page.defersCurrentPageDisplay = YES;
        [self addSubview:page];
        
        [self addObserver:self forKeyPath:@"currentColor" options:NSKeyValueObservingOptionNew context:nil];
        [self addObserver:self forKeyPath:@"nomalColor" options:NSKeyValueObservingOptionNew context:nil];
        
        // 可在这里面 设置 颜色
//        self.currentColor = [UIColor redColor];
    }
}
#pragma mark - 进入
-(void)tapEnterClick{
    NSLog(@"Tap消失事件hideGuidView");
    [self hideGuidView];
}
#pragma mark - 隐藏引导页
-(void)hideGuidView{
    [UIView animateWithDuration:0.5 animations:^{
        self.alpha = 0;
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.5 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
            [self removeFromSuperview];
        });
        
    }];
}
#pragma mark - scrollView Delegate
-(void)scrollViewWillBeginDragging:(UIScrollView *)scrollView{
    int cuttentIndex = (int)(scrollView.contentOffset.x + LScreen_width/2)/LScreen_width;
    if (cuttentIndex == images.count - 1) {
        if ([self isScrolltoLeft:scrollView]) {
            if (!isScrollOut) {
                return ;
            }
            [self hideGuidView];
        }
    }
}
-(void)scrollViewDidScroll:(UIScrollView *)scrollView{
    if (scrollView == launchScrollView) {
        int cuttentIndex = (int)(scrollView.contentOffset.x + LScreen_width/2)/LScreen_width;
        page.currentPage = cuttentIndex;
    }
}
#pragma mark - 判断滚动方向
-(BOOL )isScrolltoLeft:(UIScrollView *) scrollView{
    //返回YES为向左反动，NO为右滚动
    if ([scrollView.panGestureRecognizer translationInView:scrollView.superview].x < 0) {
        return YES;
    }else{
        return NO;
    }
}
#pragma mark - KVO监测值的变化
-(void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary<NSString *,id> *)change context:(void *)context{
    if ([keyPath isEqualToString:@"currentColor"]) {
        page.currentPageIndicatorTintColor = self.currentColor;
    }
    if ([keyPath isEqualToString:@"nomalColor"]) {
        page.pageIndicatorTintColor = self.nomalColor;
    }
}

@end
