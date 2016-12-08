//
//  ViewController.m
//  UCloudMediaRecorderDemo
//
//  Created by yisanmao on 15-3-18.
//  Copyright (c) 2015年 yisanmao. All rights reserved.
//



/**
 *  注意 关于推流路径和播放路径设置
 *  要修改textField中的推流ID同时保证推流端和播放端的ID是一样的，不能多个手机使用一个推流路径，可以多个手机播放一个路径
 */


#import "ViewController.h"
#import "ViewController.h"
#import "AppDelegate.h"
#import "FilterManager.h"
#import "sys/utsname.h"
#import "NSString+UCloudCameraCode.h"


#define SysVersion [[[UIDevice currentDevice] systemVersion] floatValue]
#ifndef LESS_IOS8
#define LESS_IOS8 ([[[UIDevice currentDevice] systemVersion] floatValue] < 8.0)
#endif


#ifndef GREATER_IOS9
#define GREATER_IOS9 ([[[UIDevice currentDevice] systemVersion] floatValue] >= 9.0)
#endif

@interface ViewController ()
{
    BOOL isload;
    BOOL isShutDown;
    UCloudGPUImageView *_frontImageView;
    
    UIView *blackView;
    NSArray *originalFilters;
    
    NSMutableArray *_registeredNotifications;
    
    NSInteger playState;
    BOOL isPublishing;
}
@property (weak, nonatomic) IBOutlet UIButton    *recordBtn;
@property (weak, nonatomic) IBOutlet UIButton    *stopBtn;
@property (weak, nonatomic) IBOutlet UIButton    *playBtn;
@property (weak, nonatomic) IBOutlet UITextField *pathTextField;
@property (weak, nonatomic) IBOutlet UILabel     *ptsLabel;
@property (weak, nonatomic) IBOutlet UILabel     *codeLabel;
@property (weak, nonatomic) IBOutlet UILabel     *modelLabel;
@property (weak, nonatomic) IBOutlet UILabel     *sysVerLabel;
@property (weak, nonatomic) IBOutlet UILabel     *lblSmooth;
@property (weak, nonatomic) IBOutlet UILabel     *lblBrightness;
@property (weak, nonatomic) IBOutlet UILabel     *lblSaturation;
@property (weak, nonatomic) IBOutlet UISlider    *sliderSmooth;
@property (weak, nonatomic) IBOutlet UISlider    *sliderBrightness;
@property (weak, nonatomic) IBOutlet UISlider    *sliderSaturation;
@property (weak, nonatomic) IBOutlet UIButton    *changeBtn;
@property (weak, nonatomic) IBOutlet UILabel     *port;
@property (weak, nonatomic) IBOutlet UIButton    *btnShutdown;
@property (weak, nonatomic) IBOutlet UIButton    *btnOpenFilter;
@property (weak, nonatomic) IBOutlet UIButton    *btnMuted;
@property (weak, nonatomic) IBOutlet UIButton    *btnTorch;
@property (weak, nonatomic) IBOutlet UIButton    *btnHorizontal;
@property (weak, nonatomic) IBOutlet UIButton    *btnVertical;
@property (weak, nonatomic) IBOutlet UIButton    *btnRouterOne;
@property (weak, nonatomic) IBOutlet UIButton    *btnRouterTwo;
@property (weak, nonatomic) IBOutlet UIButton    *btnMixAudio;

@property (strong, nonatomic) NSMutableArray  *filterValues;
@property (strong, nonatomic) FilterManager   *filterManager;
@property (strong, nonatomic) UIView          *videoView;
@property (strong, nonatomic) UIView          *waterView;
@property (strong, nonatomic) NSString        *pathStr;
@property (strong, nonatomic) NSString        *audioPathStr;//背景音乐路径
@property (strong, nonatomic) NSString        *recordDomain;
@property (strong, nonatomic) NSString        *playDomain;
@property (strong, nonatomic) AVCaptureDevice *currentDev;
@property (assign, nonatomic) BOOL            shouldAutoStarted;

@property (strong, nonatomic) NSTimer *timer;
@property (nonatomic, assign) NSInteger retryPublishNumber;

- (IBAction)btnShutdownTouchUpInside:(id)sender;
- (IBAction)btnOpenFilterTouchUpInside:(id)sender;
- (IBAction)btnMutedTouchUpInside:(id)sender;
- (IBAction)btnTorchTouchUpInside:(id)sender;
- (IBAction)switchOrientationTouchUpInside:(id)sender;
- (IBAction)switchRouterTouchUpInside:(id)sender;
- (IBAction)btnMixAudioTouchEvent:(id)sender;

@end

@implementation ViewController
- (void)viewDidLoad
{
    [super viewDidLoad];
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(noti:) name:UCloudMoviePlayerClickBack object:nil];
    
    _registeredNotifications = [[NSMutableArray alloc] init];
    
    self.retryPublishNumber = 3;
    srand((unsigned)time(NULL));
    NSInteger num = rand()%10000;
    self.pathTextField.text = [NSString stringWithFormat:@"%ld", (long)num];
    struct utsname systemInfo;
    uname(&systemInfo);
    NSURL *audioUrl   = [[NSBundle mainBundle] URLForResource: @"audioMixTest"
                                                withExtension: @"mp3"];
    self.audioPathStr = [audioUrl path];
    self.modelLabel.adjustsFontSizeToFitWidth = YES;
    self.modelLabel.text =  [NSString stringWithCString:systemInfo.machine encoding:NSUTF8StringEncoding];
    self.sysVerLabel.adjustsFontSizeToFitWidth = YES;
    self.sysVerLabel.text = [NSString stringWithFormat:@"sys:%@,sdk:%@",[[UIDevice currentDevice] systemVersion],[CameraServer server].getSDKVersion];
    [self switchRouterTouchUpInside:nil];
    [self updateOrientationBtnState:[CameraServer server].videoOrientation];
    [self setBtnStateInSel:1];
}

- (void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self name:UCloudMoviePlayerClickBack object:nil];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark - NSNotification
- (void)addNoti
{
    if (_registeredNotifications.count > 0) {
        [_registeredNotifications removeAllObjects];
    }

    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(noti:) name:UIApplicationWillEnterForegroundNotification object:nil];
    [_registeredNotifications addObject:UIApplicationWillEnterForegroundNotification];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(noti:) name:UIApplicationDidEnterBackgroundNotification object:nil];
    [_registeredNotifications addObject:UIApplicationDidEnterBackgroundNotification];
}

- (void)removeNoti
{
    for (NSString *name in _registeredNotifications) {
        [[NSNotificationCenter defaultCenter] removeObserver:self
                                                        name:name
                                                      object:nil];
    }
}

- (void)noti:(NSNotification *)noti
{
    NSLog(@"noti name :%@",noti.name);
    [[UIApplication sharedApplication] setStatusBarHidden:NO];
    if ([noti.name isEqualToString:UCloudMoviePlayerClickBack]){
        self.playerManager = nil;
        [self setBtnStateInSel:1];
    }
    else if ([noti.name isEqualToString:UIApplicationDidEnterBackgroundNotification]){
        
    }
    else if ([noti.name isEqualToString:UIApplicationWillEnterForegroundNotification]){
        
    }
}

#pragma mark - 录制
- (IBAction)record:(id)sender
{
    if (TARGET_IPHONE_SIMULATOR) {
        NSLog(@"Can't publish stream in simulator,please use iphone or ipad!");
        return;
    }

    playState = 0;
    isPublishing = YES;
    self.port.text = [NSString stringWithFormat:@"streamID:%@", self.pathTextField.text];
    
    [self addNoti];
    self.shouldAutoStarted = YES;
    
    if (![self checkPath]) {
        return;
    }
    
    if ([[CameraServer server] lowThan5]) {
        //5以下支持4：3
        [[CameraServer server] setHeight:640];
        [[CameraServer server] setWidth:480];
    }
    else {
        //5以上的支持16：9
        [[CameraServer server] setHeight:640];
        [[CameraServer server] setWidth:360];
    }
    
    [[CameraServer server] setFps:15];
    [[CameraServer server] setSupportFilter:YES];
    
    //横屏推流
    if ([CameraServer server].videoOrientation == UCloudVideoOrientationLandscapeRight) {
        if ([[UIDevice currentDevice] respondsToSelector:@selector(setOrientation:)]) {
            [[UIDevice currentDevice] performSelector:@selector(setOrientation:)
                                           withObject:@(UIInterfaceOrientationLandscapeRight)];
        }
        //宽高比例相互替换
        CGFloat width = [CameraServer server].width;
        CGFloat height = [CameraServer server].height;
        [CameraServer server].height  = width;
        [CameraServer server].width = height;
        
        if (LESS_IOS8) {
            UIApplication *application=[UIApplication sharedApplication];
            [application setStatusBarOrientation:UIInterfaceOrientationLandscapeRight];
            CGRect keyFrame = application.keyWindow.frame;
            self.view.transform = CGAffineTransformMakeRotation(-M_PI_2);
            self.view.frame = CGRectMake(0, 0, keyFrame.size.width, keyFrame.size.height);
            [self.view setNeedsUpdateConstraints];
        }
        else if (!GREATER_IOS9) {
            [self forceLandscape:UIInterfaceOrientationLandscapeRight];
        }
    }
    
    self.filterManager = [[FilterManager alloc] init];
    [self buildData];
    
    //如果需要设置显示图像的frame，iOS8以下请在此先设置，直接使用getCameraView方法获取view进行设置是无作用的，iOS8以上两者都可设置frame
//        [[CameraServer server] initializeCameraViewFrame:CGRectMake(10, 10, 240, 230)];
    [[CameraServer server] setSecretKey:AccessKey];
    [[CameraServer server] setBitrate:UCloudVideoBitrateMedium];
    if (_btnRouterOne.selected) {
        self.recordDomain = RecordDomainOne(self.pathTextField.text);
    }
    else {
        self.recordDomain = RecordDomainTwo(self.pathTextField.text);
    }

    
    NSString *path = self.recordDomain;
    __weak ViewController *weakSelf = self;
    
    self.recordBtn.enabled = NO;
    
    originalFilters = [self.filterManager filters];
    _btnOpenFilter.selected = YES;
    
    [self addWaterMark:[CameraServer server].videoOrientation];
    [[CameraServer server] configureCameraWithOutputUrl:path filter:originalFilters messageCallBack:^(UCloudCameraCode code, NSInteger arg1, NSInteger arg2, id data) {
                                            
                                            [weakSelf handlerMessageCallBackWithCode:code arg1:arg1 arg2:arg2 data:data weakSelf:weakSelf];
                                            
                                        } deviceBlock:^(AVCaptureDevice *dev) {
                                            
                                            [self handlerDeviceBlock:dev weakSelf:weakSelf];
                                            
                                        } cameraData:^CMSampleBufferRef(CMSampleBufferRef buffer) {
                                            //如果不需要裸流，不建议在这里执行操作，将增加额外的功耗
                                            return nil;
                                        }];
    [UIApplication sharedApplication].idleTimerDisabled = YES;
    
    if (!self.timer){
        self.timer = [NSTimer scheduledTimerWithTimeInterval:1.0f target:self selector:@selector(getBitrate) userInfo:nil repeats:YES];
    }
    
}

- (void)addWaterMark:(UCloudVideoOrientation)videoOrient
{
    
    if (self.waterView == nil) {
        CGSize size;
        CGSize sizeOrigin = [UIScreen mainScreen].bounds.size;
        if (videoOrient == UCloudVideoOrientationLandscapeRight ||
            videoOrient == UCloudVideoOrientationLandscapeLeft) {
            if (sizeOrigin.width < sizeOrigin.height) {
                size = CGSizeMake(sizeOrigin.height, sizeOrigin.width);
            }
            else {
                size = sizeOrigin;
            }
        }
        else {
            
            if (sizeOrigin.width > sizeOrigin.height) {
                size = CGSizeMake(sizeOrigin.height, sizeOrigin.width);
            }
            else {
                size = sizeOrigin;
            }
            
        }
        __block UILabel *label = [[UILabel alloc] initWithFrame:CGRectMake(0, 0, size.width, 44)];
        label.textAlignment = NSTextAlignmentCenter;
        label.text = @"我是水印";
        UIImageView *imgV = [[UIImageView alloc]initWithFrame:CGRectMake(size.width/2 -20, _changeBtn.frame.origin.y + 40, 60, 60)];
        imgV.image = [UIImage imageNamed:@"ucloud_logo"];
        imgV.alpha = 0.5;
        UIView *subView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, size.width, size.height)];
        subView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
        subView.backgroundColor = [UIColor clearColor];
        [subView addSubview:label];
        [subView addSubview:imgV];
        self.waterView = subView;
        NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
        [dateFormatter setDateFormat:@"yyyy-MM-dd HH:mm:ss"];
        [[CameraServer server] setWatermarkView:subView Block:^{
            label.text = [NSString stringWithFormat:@"UCloud:%@", [dateFormatter stringFromDate: [NSDate date]]];
        }];
    }
}

- (void)removeWaterMark
{
    if (self.waterView) {
        NSArray* subViewS = [self.waterView subviews];
        for (UIView* subView in subViewS) {
            [subView removeFromSuperview];
        }
        [self.waterView removeFromSuperview];
        self.waterView = nil;
    }
    
}

- (void)handlerMessageCallBackWithCode:(UCloudCameraCode)code arg1:(NSInteger)arg1 arg2:(NSInteger)arg2 data:(id)data weakSelf:(ViewController *)weakSelf
{
    
    NSLog(@"code:%ld arg1:%ld arg2:%ld", (long)code, (long)arg1, (long)arg2);
    
    NSString *codeStr = [NSString stringWithFormat:@"%ld",(unsigned long)code];
    self.codeLabel.text = [NSString stringWithFormat:@"state:%@",[codeStr cameraCodeToMessage]];
    
    if (code == UCloudCamera_Permission) {
        UIAlertView *alterView = [[UIAlertView alloc] initWithTitle:@"相机授权" message:@"没有权限访问您的相机，请在“设置－隐私－相机”中允许使用" delegate:nil cancelButtonTitle:@"取消" otherButtonTitles:nil, nil];
        [alterView show];
        weakSelf.recordBtn.enabled = YES;
    }
    else if (code == UCloudCamera_Micphone) {
        [[[UIAlertView alloc] initWithTitle:@"麦克风授权" message:@"没有权限访问您的麦克风，请在“设置－隐私－麦克风”中允许使用" delegate:nil cancelButtonTitle:@"取消" otherButtonTitles:nil, nil] show];
        weakSelf.recordBtn.enabled = YES;
    }
    else if (code == UCloudCamera_SecretkeyNil) {
        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Warning" message:@"密钥为空" delegate:self cancelButtonTitle:@"OK" otherButtonTitles:nil, nil];
        [alert show];
        [weakSelf setBtnStateInSel:1];
    }
    else if (code == UCloudCamera_AuthFail) {
        NSDictionary *dic = data;
        NSError *error = dic[@"error"];
        NSLog(@"errcode:%@\n msg:%@\n errdesc:%@", dic[@"retcode"], dic[@"message"], error.description);
        weakSelf.recordBtn.enabled = YES;
    }
    else if (code == UCloudCamera_PreviewOK) {
        [self.videoView removeFromSuperview];
        self.videoView = nil;
        [weakSelf startPreview];
    }
    else if (code == UCloudCamera_PublishOk) {
        [[CameraServer server] cameraStart];
        [weakSelf setBtnStateInSel:3];
        weakSelf.recordBtn.enabled = YES;
        
        [weakSelf.filterManager setCurrentValue:weakSelf.filterValues];
    }
    else if (code == UCloudCamera_StartPublish) {
        weakSelf.recordBtn.enabled = YES;
    }
    else if (code == UCloudCamera_OUTPUT_ERROR) {
        weakSelf.recordBtn.enabled = YES;
    }
    else if (code == UCloudCamera_BUFFER_OVERFLOW) {
        
    }
}

- (void)handlerDeviceBlock:(AVCaptureDevice *)dev weakSelf:(UIViewController *)weakSelf
{
    
}

- (void) startPreview
{
    UIView *cameraView = [[CameraServer server] getCameraView];
    cameraView.backgroundColor = [UIColor whiteColor];
    [self.view addSubview:cameraView];
    [self.view sendSubviewToBack:cameraView];
    self.videoView = cameraView;
}

- (IBAction)stopCamera:(id)sender
{
    isPublishing = NO;
    self.shouldAutoStarted = NO;
    self.stopBtn.enabled = NO;
    __weak ViewController *weakSelf = self;
    [self.timer invalidate];
    self.timer = nil;
    _btnMixAudio.selected = NO;
    [CameraServer server].backgroudMusicOn = NO;
    [[CameraServer server] setBackgroudMusicOn:NO];
    [[CameraServer server] shutdown:^{
        if (weakSelf.videoView) {
            [weakSelf.videoView removeFromSuperview];
        }
        
        [self removeWaterMark];
        weakSelf.videoView = nil;
        self.stopBtn.enabled = YES;
        [weakSelf setBtnStateInSel:1];
        
        if ([CameraServer server].videoOrientation == UCloudVideoOrientationLandscapeRight) {
            [CameraServer server].videoOrientation = UCloudVideoOrientationPortrait;
            [[UIDevice currentDevice] setValue:
             [NSNumber numberWithInteger:UIInterfaceOrientationPortrait]
                                        forKey:@"orientation"];
            [self switchOrientationTouchUpInside:nil];
            
            if (LESS_IOS8) {
                UIApplication *application=[UIApplication sharedApplication];
                [application setStatusBarOrientation:UIInterfaceOrientationPortrait];
                CGRect keyFrame = application.keyWindow.frame;
                self.view.transform = CGAffineTransformMakeRotation(0);
                self.view.frame = CGRectMake(0, 0, keyFrame.size.width, keyFrame.size.height);
                [self.view setNeedsUpdateConstraints];

            }
            else if (!GREATER_IOS9) {
                [self forceLandscape:UIInterfaceOrientationPortrait];
            }
            [UIViewController attemptRotationToDeviceOrientation];
        }
    }];
    [UIApplication sharedApplication].idleTimerDisabled = NO;
    [self removeNoti];
}

- (IBAction)changeCamera:(id)sender
{
    self.changeBtn.enabled = NO;
    [[CameraServer server] changeCamera];
    self.changeBtn.enabled = YES;
    
    if([[CameraServer server] currentCapturePosition] == AVCaptureDevicePositionBack){
        self.btnTorch.enabled = YES;
    } else {
        self.btnTorch.enabled = NO;
        if (self.btnTorch.selected) {
            self.btnTorch.selected = NO;
        }
    }
}

- (IBAction)sliderChanged:(UISlider *)sender
{
    NSDictionary *info = self.filterValues[sender.tag - 1000];
    NSMutableDictionary *mutableInfo = [NSMutableDictionary dictionaryWithDictionary:info];
    mutableInfo[@"current"] = @(sender.value);
    [self.filterValues replaceObjectAtIndex:[self.filterValues indexOfObject:info] withObject:mutableInfo];
    
    NSString *name = info[@"type"];
    float a = sender.value;
    [self.filterManager valueChange:name value:a];
}

- (void)getBitrate
{
    NSString *str = [[CameraServer server] outBitrate];
    self.ptsLabel.text = [NSString stringWithFormat:@"bitrate:%@", str];
}

#pragma mark - 播放
- (IBAction)play:(id)sender
{
    if ([self checkPath]) {
        [[AVAudioSession sharedInstance] setCategory:AVAudioSessionCategoryPlayAndRecord error:nil];
        AppDelegate *delegate = [UIApplication sharedApplication].delegate;
        delegate.vc = self;
        self.playerManager = [[PlayerManager alloc] init];
        self.playerManager.view = self.view;
        self.playerManager.viewContorller = self;
        //        [self.playerManager setSupportAutomaticRotation:YES];
        //        [self.playerManager setSupportAngleChange:YES];
        float height = self.view.frame.size.height;
        [self.playerManager setPortraitViewHeight:height];
        if (_btnRouterOne.selected) {
            self.playDomain = PlayDomainOne(self.pathTextField.text);
        }
        else {
            self.playDomain = PlayDomainTwo(self.pathTextField.text);
        }
        
        [self.playerManager buildMediaPlayer:self.playDomain];
        [self setBtnStateInSel:2];
    }
    [self.view bringSubviewToFront:_btnShutdown];
    
    playState = 1;
}

#pragma mark - Interface Orientation

//强制旋转设备
- (void)forceLandscape:(UIInterfaceOrientation)orientation
{
    UIDevice  *myDevice = [UIDevice currentDevice];
    if([myDevice respondsToSelector:@selector(setOrientation:)]) {
        NSInteger param;
        
        param = orientation;
        
        NSMethodSignature *signature  = [[myDevice class] instanceMethodSignatureForSelector:@selector(setOrientation:)];
        NSInvocation      *invocation = [NSInvocation invocationWithMethodSignature:signature];
        [invocation setTarget:myDevice];
        [invocation setSelector:@selector(setOrientation:)];
        [invocation setArgument:&param
                        atIndex:2];
        [invocation invoke];
    }
    AppDelegate *appdelegate=(AppDelegate *)[UIApplication sharedApplication].delegate;
    [appdelegate application:[UIApplication sharedApplication] supportedInterfaceOrientationsForWindow:self.view.window];
}

-(UIInterfaceOrientationMask)supportedInterfaceOrientations
{
    if (self.playerManager) {
        return self.playerManager.supportInterOrtation;
    }
    else {
        /**
         *  这个在播放之外的程序支持的设备方向
         */
        if ([CameraServer server].videoOrientation == UCloudVideoOrientationLandscapeRight && playState == 0 && isPublishing) {
            return UIInterfaceOrientationMaskLandscapeRight;
        }

        return UIInterfaceOrientationMaskPortrait;
    }
}

- (void)didRotateFromInterfaceOrientation:(UIInterfaceOrientation)fromInterfaceOrientation
{
    if (self.playerManager) {
        [self.playerManager rotateEnd];
    }
}

- (void)willRotateToInterfaceOrientation:(UIInterfaceOrientation)toInterfaceOrientation duration:(NSTimeInterval)duration
{
    if (self.playerManager) {
        [self.playerManager rotateBegain:toInterfaceOrientation];
    }
}

- (void)touchesBegan:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event
{
    if ([self.pathTextField isFirstResponder]) {
        [self.pathTextField resignFirstResponder];
    }
}

#pragma mark - UIButton Method
- (IBAction)btnShutdownTouchUpInside:(id)sender
{
    // 关闭重播放
    [NSObject cancelPreviousPerformRequestsWithTarget:self.playerManager];

    [self.playerManager.mediaPlayer.player.view removeFromSuperview];
    [self.playerManager.controlVC.view removeFromSuperview];
    [self.playerManager.mediaPlayer.player shutdown];
    self.playerManager.mediaPlayer = nil;
    
    {
        self.playerManager.supportInterOrtation = UIInterfaceOrientationMaskPortrait;
        [self.playerManager awakeSupportInterOrtation:self.playerManager.viewContorller completion:^{
            self.playerManager.supportInterOrtation = UIInterfaceOrientationMaskAllButUpsideDown;
        }];
    }
    
    [[NSNotificationCenter defaultCenter] postNotificationName:UCloudMoviePlayerClickBack object:self.playerManager];
    
}

- (IBAction)btnOpenFilterTouchUpInside:(id)sender {
    if (_btnOpenFilter.selected) {
        _btnOpenFilter.selected = NO;
        [[CameraServer server] closeFilter];
    }
    else {
        _btnOpenFilter.selected = YES;
        originalFilters = [self.filterManager filters];
        [[CameraServer server] openFilter];
    }
}

- (IBAction)btnMutedTouchUpInside:(id)sender {
    [CameraServer server].muted = ![CameraServer server].muted;
    _btnMuted.selected = [CameraServer server].muted;
}

- (IBAction)btnTorchTouchUpInside:(id)sender{
    if (_btnTorch.selected) {
        _btnTorch.selected = NO;
        [[CameraServer server] setTorchState:UCloudCameraCode_Off];
    }
    else {
        _btnTorch.selected = YES;
        [[CameraServer server] setTorchState:UCloudCameraCode_On];
    }
}

- (IBAction)switchOrientationTouchUpInside:(id)sender {
    NSInteger touchOrientation;
    
    if(sender == _btnVertical) {
        [[CameraServer server] setVideoOrientation:UCloudVideoOrientationPortrait];
        touchOrientation = UCloudVideoOrientationPortrait;
    }
    else {
        [[CameraServer server] setVideoOrientation:UCloudVideoOrientationLandscapeRight];
        touchOrientation = UCloudVideoOrientationLandscapeRight;
    }
    
    [self updateOrientationBtnState:touchOrientation];
}

- (void)updateOrientationBtnState:(UCloudVideoOrientation)orientation
{
    if (orientation != UCloudVideoOrientationPortrait) {
        _btnVertical.selected = NO;
        _btnHorizontal.selected = YES;
    }
    else {
        _btnVertical.selected = YES;
        _btnHorizontal.selected = NO;
    }
}

- (IBAction)switchRouterTouchUpInside:(id)sender {
    self.playDomain = PlayDomainOne(self.pathTextField.text);
    self.recordDomain = RecordDomainOne(self.pathTextField.text);
    
    if(sender != _btnRouterTwo) {
        _btnRouterOne.selected = YES;
        _btnRouterTwo.selected = NO;
    }
    else {
        _btnRouterOne.selected = NO;
        _btnRouterTwo.selected = YES;
    }
}

- (IBAction)btnMixAudioTouchEvent:(id)sender {
    
    if (_btnMixAudio.selected) {
        _btnMixAudio.selected = NO;
    }
    else {
        _btnMixAudio.selected = YES;
    }
    [CameraServer server].audioPlayStr = self.audioPathStr;
    [CameraServer server].backgroudMusicOn = ![CameraServer server].backgroudMusicOn;
}

#pragma mark - Custom Method

- (void)setBtnStateInSel:(NSInteger)num
{
    if (num == 1) {
        //初始状态
        self.recordBtn.hidden     = NO;
        self.stopBtn.hidden       = YES;
        self.playBtn.hidden       = NO;
        self.ptsLabel.hidden      = YES;
        self.port.hidden          = YES;
        self.pathTextField.hidden = NO;
        self.sliderSmooth.hidden  = YES;
        self.sliderBrightness.hidden  = YES;
        self.sliderSaturation.hidden  = YES;
        self.lblSmooth.hidden     = YES;
        self.lblBrightness.hidden = YES;
        self.lblSaturation.hidden = YES;
        self.changeBtn.hidden     = YES;
        self.btnShutdown.hidden   = YES;
        self.btnOpenFilter.hidden = YES;
        self.btnMuted.hidden      = YES;
        self.btnTorch.hidden = YES;
        self.btnHorizontal.hidden = NO;
        self.btnVertical.hidden = NO;
        self.btnRouterOne.hidden = NO;
        self.btnRouterTwo.hidden = NO;
        self.btnMixAudio.hidden = YES;
    }
    else if (num == 2) {
        //选择play
        self.recordBtn.hidden     = YES;
        self.stopBtn.hidden       = YES;
        self.playBtn.hidden       = YES;
        self.ptsLabel.hidden      = YES;
        self.port.hidden          = YES;
        self.pathTextField.hidden = YES;
        self.sliderSmooth.hidden  = YES;
        self.sliderBrightness.hidden  = YES;
        self.sliderSaturation.hidden  = YES;
        self.lblSmooth.hidden     = YES;
        self.lblBrightness.hidden = YES;
        self.lblSaturation.hidden = YES;
        self.changeBtn.hidden     = YES;
        self.codeLabel.hidden     = YES;
        self.modelLabel.hidden    = YES;
        self.sysVerLabel.hidden   = YES;
        self.btnOpenFilter.hidden = YES;
        self.btnShutdown.hidden   = NO;
        self.btnMuted.hidden      = YES;
        self.btnTorch.hidden = YES;
        self.btnMixAudio.hidden = YES;
        self.btnHorizontal.hidden = YES;
        self.btnVertical.hidden = YES;
        self.btnRouterOne.hidden = YES;
        self.btnRouterTwo.hidden = YES;
    }
    else if (num == 3) {
        //选择camera
        self.recordBtn.hidden     = YES;
        self.stopBtn.hidden       = NO;
        self.playBtn.hidden       = YES;
        self.ptsLabel.hidden      = NO;
        self.codeLabel.hidden     = NO;
        self.modelLabel.hidden    = NO;
        self.sysVerLabel.hidden   = NO;
        self.port.hidden          = NO;
        self.btnOpenFilter.hidden = NO;
        self.pathTextField.hidden = YES;
        self.sliderSmooth.hidden  = NO;
        self.sliderBrightness.hidden  = NO;
        self.sliderSaturation.hidden  = NO;
        self.lblSmooth.hidden     = NO;
        self.lblBrightness.hidden = NO;
        self.lblSaturation.hidden = NO;
        self.changeBtn.hidden     = NO;
        self.btnShutdown.hidden   = YES;
        self.btnMuted.hidden      = NO;
        self.btnTorch.hidden = NO;
        if ([CameraServer server].captureDevicePos == AVCaptureDevicePositionFront) {
            self.btnTorch.enabled = NO;
        }
        else {
            self.btnTorch.enabled = YES;
        }
        self.btnHorizontal.hidden = YES;
        self.btnVertical.hidden = YES;
        self.btnRouterOne.hidden = YES;
        self.btnRouterTwo.hidden = YES;
        self.btnMixAudio.hidden = NO;
        if (self.filterValues.count > 0) {
            self.sliderSmooth.hidden     = NO;
            self.sliderBrightness.hidden  = NO;
            self.sliderSaturation.hidden  = NO;
            self.lblSmooth.hidden     = NO;
            self.lblBrightness.hidden = NO;
            self.lblSaturation.hidden = NO;
        }
        else {
            self.sliderSmooth.hidden     = YES;
            self.sliderBrightness.hidden     = YES;
            self.sliderSaturation.hidden     = YES;
            self.lblSmooth.hidden     = YES;
            self.lblBrightness.hidden = YES;
            self.lblSaturation.hidden = YES;
        }
    }
}

- (BOOL)checkPath
{
    if (self.pathTextField.text.length == 0) {
        UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:@"Warning" message:@"Path can not null" delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil, nil];
        [alertView show];
        [alertView becomeFirstResponder];
        return NO;
    }
    else {
        return YES;
    }
}

- (void)buildData
{
    self.filterValues = [self.filterManager buildData];
    if (!self.filterValues) {
        _sliderSmooth.hidden = _sliderBrightness.hidden = _sliderSaturation.hidden = YES;
        _lblSmooth.hidden = _lblBrightness.hidden = _lblSaturation.hidden = YES;
        return;
    }
    
    NSDictionary *smoothInfo = _filterValues[0];
    _sliderSmooth.minimumValue = [smoothInfo[@"min"] floatValue];
    _sliderSmooth.maximumValue = [smoothInfo[@"max"] floatValue];
    _sliderSmooth.value  = [smoothInfo[@"current"] floatValue];
    
    NSDictionary *brightnessInfo = _filterValues[1];
    _sliderBrightness.minimumValue = [brightnessInfo[@"min"] floatValue];
    _sliderBrightness.maximumValue = [brightnessInfo[@"max"] floatValue];
    _sliderBrightness.value  = [brightnessInfo[@"current"] floatValue];
    
    NSDictionary *saturationInfo = _filterValues[2];
    _sliderSaturation.minimumValue = [saturationInfo[@"min"] floatValue];
    _sliderSaturation.maximumValue = [saturationInfo[@"max"] floatValue];
    _sliderSaturation.value  = [saturationInfo[@"current"] floatValue];
}

@end
