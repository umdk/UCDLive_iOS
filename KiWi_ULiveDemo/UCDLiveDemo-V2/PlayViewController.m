//
//  PlayViewController.m
//  UCDVodDemo-V2
//
//  Created by Sidney on 16/03/17.
//  Copyright © 2017年 https://ucloud.cn. All rights reserved.
//

#import "PlayViewController.h"
#import "JGProgressHUD.h"
#import "UCloudMediaPlayer.h"
#import "UCDLiveDemoHeader.h"

@interface PlayViewController ()

@property (strong, nonatomic) UCloudMediaPlayer *mediaPlayer;
@property (strong, nonatomic) JGProgressHUD *jgHud;
@property (nonatomic, assign) NSInteger retryConnectNumber;
@property (nonatomic, strong) UIAlertView *retryAlert;
@property (assign, nonatomic) BOOL isPrepared;

@end


@implementation PlayViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view, typically from a nib.
    
    self.retryConnectNumber = 3;
    _retryAlert = [[UIAlertView alloc] initWithTitle:@"重连" message:@"" delegate:self cancelButtonTitle:@"知道了"   otherButtonTitles: nil, nil];
    
    [self addNotification];
    
    [self showLoadingView];
    [self buildMediaPlayer:_playUrl];
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    self.navigationController.navigationBarHidden = YES;
}

- (void)viewWillDisappear:(BOOL)animated
{
    [super viewWillDisappear:animated];
    self.navigationController.navigationBarHidden = NO;
}


- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark - Player

- (void)buildMediaPlayer:(NSString *)path
{
    self.mediaPlayer = [UCloudMediaPlayer ucloudMediaPlayer];
    
    if ([_playUrl.pathExtension hasSuffix:@"m3u8"]) {
        //HLS如果对累积延时没要求，建议把setCachedDuration设置为0(即关闭消除累积延时功能)，这样播放过程中卡顿率会更低
        _mediaPlayer.cachedDuration = 0;
        _mediaPlayer.bufferDuration = 3000;
    } else {
        _mediaPlayer.cachedDuration = 3000;
        _mediaPlayer.bufferDuration = 3000;
    }
    
    [self.mediaPlayer showMediaPlayer:_playUrl
                              urltype:UrlTypeLive
                                frame:self.view.frame
                                 view:self.sdlView
                           completion:^(NSInteger defaultNum, NSArray *data) {
                               //在此可以控制UI布局
                           }];
}

- (IBAction)btnStopTouchUpInside:(id)sender {
    
    [self.mediaPlayer.player.view removeFromSuperview];
    [self.mediaPlayer.player shutdown];
    self.mediaPlayer = nil;
    
    [self.navigationController popViewControllerAnimated:YES];
}

- (void)restartPlayer
{
    [self.mediaPlayer.player.view removeFromSuperview];
    [self.mediaPlayer.player shutdown];
    self.mediaPlayer = nil;
    
    [self buildMediaPlayer:_playUrl];
    _retryConnectNumber--;
}

#pragma mark - notification
- (void)addNotification
{
    [NotificationCenter addObserver:self selector:@selector(livePrepare:) name:UCloudPlaybackIsPreparedToPlayDidChangeNotification object:nil];
    [NotificationCenter addObserver:self selector:@selector(liveLoadStateChange:) name:UCloudPlayerLoadStateDidChangeNotification object:nil];
    [NotificationCenter addObserver:self selector:@selector(livePlaybackStateChange:) name:UCloudPlayerPlaybackStateDidChangeNotification object:nil];
    [NotificationCenter addObserver:self selector:@selector(livePlaybackDidFinish:) name:UCloudPlayerPlaybackDidFinishNotification object:nil];
    
    [NotificationCenter addObserver:self selector:@selector(liveBufferUpdate:) name:UCloudPlayerBufferingUpdateNotification object:nil];
    [NotificationCenter addObserver:self selector:@selector(liveVideoChangeRotation:) name:UCloudPlayerVideoChangeRotationNotification object:nil];
    
    // 监测设备方向
    [[UIDevice currentDevice] beginGeneratingDeviceOrientationNotifications];
    [NotificationCenter addObserver:self selector:@selector(onDeviceOrientationChange) name:UIDeviceOrientationDidChangeNotification object:nil];
    
    [NotificationCenter addObserver:self selector:@selector(onStatusBarOrientationChange) name:UIApplicationDidChangeStatusBarOrientationNotification object:nil];
}

- (void)removeNotification
{
    [NotificationCenter removeObserver:self name:UCloudPlaybackIsPreparedToPlayDidChangeNotification object:nil];
    [NotificationCenter removeObserver:self name:UCloudPlayerLoadStateDidChangeNotification object:nil];
    [NotificationCenter removeObserver:self name:UCloudMoviePlayerSeekCompleted object:nil];
    [NotificationCenter removeObserver:self name:UCloudPlayerPlaybackStateDidChangeNotification object:nil];
    [NotificationCenter removeObserver:self name:UCloudPlayerPlaybackDidFinishNotification object:nil];
    [NotificationCenter removeObserver:self name:UCloudPlayerBufferingUpdateNotification object:nil];
    [NotificationCenter removeObserver:self name:UCloudPlayerVideoChangeRotationNotification object:nil];
}

- (void)dealloc
{
    [self removeNotification];
    // 移除通知
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    [[UIDevice currentDevice] endGeneratingDeviceOrientationNotifications];
}

#pragma mark - NSNotification
- (void)livePrepare:(NSNotification *)notification
{
    NSLog(@"%s", __FUNCTION__);
    [self hideLoadingView];
    _isPrepared = YES;
}

- (void)liveLoadStateChange:(NSNotification *)notification
{
    NSLog(@"%s", __FUNCTION__);
    if ([self.mediaPlayer.player loadState] == MPMovieLoadStateStalled) {
        //网速不好，开始缓冲
        [self showLoadingView];
    }
    else if ([self.mediaPlayer.player loadState] == (MPMovieLoadStatePlayable|MPMovieLoadStatePlaythroughOK)) {
        //缓冲完毕
        [self hideLoadingView];
    }
}

- (void)livePlaybackStateChange:(NSNotification *)notification
{
    NSLog(@"%s", __FUNCTION__);
    NSLog(@"backState:%ld", (long)[self.mediaPlayer.player playbackState]);
    if (!self.isPrepared) {
        self.isPrepared = YES;
        [self.mediaPlayer.player play];
    }
    if (self.mediaPlayer.player.playbackState == 2) {
        [self hideLoadingView];
    }
}

- (void)livePlaybackDidFinish:(NSNotification *)notification
{
    NSLog(@"%s", __FUNCTION__);
    MPMovieFinishReason reson = [[notification.userInfo objectForKey:MPMoviePlayerPlaybackDidFinishReasonUserInfoKey] integerValue];
    SubErrorCode subErrorCode = [[notification.userInfo objectForKey:@"error"] integerValue];
    
    //播放结束
    if (reson == MPMovieFinishReasonPlaybackEnded) {
        [self.mediaPlayer.player pause];
        
        //部分cdn对于主播中途退出的情况也定义为播放结束，如果客户有自己的信令服务则可以自己来管理主播掉线、切后台、退出等状态，如果没有自己的信令服务则可以在此添加重连的机制，具体可以参考下面的出错重连代码。
    }
    //播放出错
    else if (reson == MPMovieFinishReasonPlaybackError) {
        NSLog(@"player manager finish reason playback error! subErrorCode:%ld",(long)subErrorCode);
        
        // 尝试重连，注意这里需要你自己来处理重连尝试的次数以及重连的时间间隔
        if (_retryConnectNumber > 0) {
            NSLog(@"视频播放错误，小U君正在为您抢救，剩余次数%ld", (long)_retryConnectNumber);
            [self performSelector:@selector(restartPlayer) withObject:self afterDelay:1.0f];
            
            return;
        }
        
        _retryAlert.message = @"视频播放错误，请稍候再试";
        [_retryAlert show];
    }
}

- (void)liveBufferUpdate:(NSNotification *)notification
{
    NSLog(@"%s", __FUNCTION__);
}

- (void)rotateBegin:(UIInterfaceOrientation)noti
{
    NSLog(@"%s", __FUNCTION__);
//    [self deviceOrientationChanged:noti];
    //重绘画面
    [self.mediaPlayer refreshView];
}

- (void)rotateEnd
{
    NSLog(@"%s", __FUNCTION__);
    //重绘画面
    [self.mediaPlayer refreshView];
}

- (void)liveVideoChangeRotation:(NSNotification *)notification
{
    NSLog(@"%s", __FUNCTION__);
    NSInteger rotation = [notification.object integerValue];
    self.mediaPlayer.player.view.transform = CGAffineTransformIdentity;
    
    switch (rotation) {
        case 0: {
            self.mediaPlayer.player.view.transform = CGAffineTransformIdentity;
        }
            break;
        case 90: {
            self.mediaPlayer.player.view.transform = CGAffineTransformMakeRotation(-M_PI_2);
        }
            break;
        case 180: {
            self.mediaPlayer.player.view.transform = CGAffineTransformMakeRotation(-M_PI);
        }
            break;
        case 270: {
            self.mediaPlayer.player.view.transform = CGAffineTransformMakeRotation(-(M_PI+M_PI_2));
        }
            break;
        default:
            break;
    }
    [self.mediaPlayer.player.view updateConstraintsIfNeeded];
}


static bool showing = NO;
#pragma mark - loading view
- (void)showLoadingView
{
    if (!showing)
    {
        showing = YES;
        
        _jgHud = [JGProgressHUD progressHUDWithStyle:JGProgressHUDStyleDark];
        _jgHud.textLabel.text = @"加载中";
        [_jgHud showInView:self.hudView];
    }
}

- (void)hideLoadingView
{
    showing = NO;
    [_jgHud dismissAnimated:YES];
}

#pragma mark - 方向
/**
 *  设置横屏的约束
 */
- (void)setOrientationLandscapeConstraint:(UIInterfaceOrientation)orientation {
    [self toOrientation:orientation];
}

/**
 *  设置竖屏的约束
 */
- (void)setOrientationPortraitConstraint {
    [self toOrientation:UIInterfaceOrientationPortrait];
}

- (void)toOrientation:(UIInterfaceOrientation)orientation {
    // 获取到当前状态条的方向
    UIInterfaceOrientation currentOrientation = [UIApplication sharedApplication].statusBarOrientation;
    // 判断如果当前方向和要旋转的方向一致,那么不做任何操作
//    if (currentOrientation == orientation) { return; }
    
    // 根据要旋转的方向,使用Masonry重新修改限制
    if (orientation != UIInterfaceOrientationPortrait) {//
        // 这个地方加判断是为了从全屏的一侧,直接到全屏的另一侧不用修改限制,否则会出错;
        if (currentOrientation == UIInterfaceOrientationPortrait) {
//            [self removeFromSuperview];
//            [self mas_remakeConstraints:^(MASConstraintMaker *make) {
//                make.width.equalTo(@(ScreenHeight));
//                make.height.equalTo(@(ScreenWidth));
//                make.center.equalTo([UIApplication sharedApplication].keyWindow);
//            }];
        }
    }
    // iOS6.0之后,设置状态条的方法能使用的前提是shouldAutorotate为NO,也就是说这个视图控制器内,旋转要关掉;
    // 也就是说在实现这个方法的时候-(BOOL)shouldAutorotate返回值要为NO
    [[UIApplication sharedApplication] setStatusBarOrientation:orientation animated:NO];
    // 获取旋转状态条需要的时间:
    [UIView beginAnimations:nil context:nil];
    [UIView setAnimationDuration:0.3];
    // 更改了状态条的方向,但是设备方向UIInterfaceOrientation还是正方向的,这就要设置给你播放视频的视图的方向设置旋转
    // 给你的播放视频的view视图设置旋转
//    self.mediaPlayer.player.view.transform = CGAffineTransformIdentity;
//    self.mediaPlayer.player.view.transform = [self getTransformRotationAngle];
    self.mediaPlayer.player.view.frame = _sdlView.frame;
    [self.mediaPlayer refreshView];
    // 开始旋转
    [UIView commitAnimations];
}

/**
 * 获取变换的旋转角度
 *
 * @return 角度
 */
- (CGAffineTransform)getTransformRotationAngle {
    // 状态条的方向已经设置过,所以这个就是你想要旋转的方向
    UIInterfaceOrientation orientation = [UIApplication sharedApplication].statusBarOrientation;
    // 根据要进行旋转的方向来计算旋转的角度
    if (orientation == UIInterfaceOrientationPortrait) {
        return CGAffineTransformIdentity;
    } else if (orientation == UIInterfaceOrientationLandscapeLeft){
        return CGAffineTransformMakeRotation(-M_PI_2);
    } else if(orientation == UIInterfaceOrientationLandscapeRight){
        return CGAffineTransformMakeRotation(M_PI_2);
    }
    return CGAffineTransformIdentity;
}

#pragma mark 屏幕转屏相关

/**
 *  屏幕转屏
 *
 *  @param orientation 屏幕方向
 */
- (void)interfaceOrientation:(UIInterfaceOrientation)orientation {
    if (orientation == UIInterfaceOrientationLandscapeRight || orientation == UIInterfaceOrientationLandscapeLeft) {
        // 设置横屏
        [self setOrientationLandscapeConstraint:orientation];
    } else if (orientation == UIInterfaceOrientationPortrait) {
        // 设置竖屏
        [self setOrientationPortraitConstraint];
    }
}

/**
 *  屏幕方向发生变化会调用这里
 */
- (void)onDeviceOrientationChange {
    if (!self.mediaPlayer) { return; }
    UIDeviceOrientation orientation = [UIDevice currentDevice].orientation;
    UIInterfaceOrientation interfaceOrientation = (UIInterfaceOrientation)orientation;
    if (orientation == UIDeviceOrientationFaceUp || orientation == UIDeviceOrientationFaceDown || orientation == UIDeviceOrientationUnknown ) { return; }
    
    switch (interfaceOrientation) {
        case UIInterfaceOrientationPortrait:
                [self toOrientation:UIInterfaceOrientationPortrait];
            break;
        case UIInterfaceOrientationLandscapeLeft:{
//            if (self.isFullScreen == NO) {
//                [self toOrientation:UIInterfaceOrientationLandscapeLeft];
//                self.isFullScreen = YES;
//            } else {
                [self toOrientation:UIInterfaceOrientationLandscapeLeft];
//            }
            
        }
            break;
        case UIInterfaceOrientationLandscapeRight:{
//            if (self.isFullScreen == NO) {
//                [self toOrientation:UIInterfaceOrientationLandscapeRight];
//                self.isFullScreen = YES;
//            } else {
                [self toOrientation:UIInterfaceOrientationLandscapeRight];
//            }
        }
            break;
        default:
            break;
    }
}

// 状态条变化通知
- (void)onStatusBarOrientationChange {
    // 获取到当前状态条的方向
    UIInterfaceOrientation currentOrientation = [UIApplication sharedApplication].statusBarOrientation;
    if (currentOrientation == UIInterfaceOrientationPortrait) {
        [self setOrientationPortraitConstraint];
    } else {
        if (currentOrientation == UIInterfaceOrientationLandscapeRight) {
            [self toOrientation:UIInterfaceOrientationLandscapeRight];
        } else if (currentOrientation == UIDeviceOrientationLandscapeLeft){
            [self toOrientation:UIInterfaceOrientationLandscapeLeft];
        }
        
    }
}

#pragma mark - Orientation
- (BOOL)shouldAutorotate{
    //是否允许转屏
    if (!_isPortrait) {
        return YES;
    }
    
    return NO;
}

- (UIInterfaceOrientationMask)supportedInterfaceOrientations
{
    return UIInterfaceOrientationMaskPortrait | UIInterfaceOrientationMaskLandscapeLeft | UIInterfaceOrientationMaskLandscapeRight;
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)toInterfaceOrientation
{
    if (!_isPortrait) {
        return (toInterfaceOrientation == UIInterfaceOrientationPortrait);
    }
    return (toInterfaceOrientation == UIInterfaceOrientationLandscapeLeft);
}

- (UIInterfaceOrientation)preferredInterfaceOrientationForPresentation
{
    //viewController初始显示的方向
    if (!_isPortrait) {
        return UIInterfaceOrientationLandscapeLeft;
    }

    return UIInterfaceOrientationPortrait;
}

@end
