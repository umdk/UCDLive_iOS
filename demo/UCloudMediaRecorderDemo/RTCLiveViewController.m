//
//  RTCLiveViewController.m
//  UCloudMediaRecorderDemo
//
//  Created by Sidney on 23/05/17.
//  Copyright © 2017年 https://ucloud.cn. All rights reserved.
//

#import "RTCLiveViewController.h"
#import "UCDLiveDemoHeader.h"
#import "ZJLogTextView.h"
#import "PopoverView.h"
#import "NetworkInfo.h"

#import "UCDAgoraClient.h"
#import "UCDAgoraServiceKit.h"

/*!
 rtmp直播支持横竖屏，直播连麦暂支持竖屏
 */
@interface RTCLiveViewController ()<UIAlertViewDelegate>
{
    NSArray *liveFilters;
    BOOL isFirstStream;
}

@property (strong, nonatomic) UIView *videoView;
@property (weak, nonatomic) IBOutlet UIView *sdlView;
@property (weak, nonatomic) UIView *waterMarkView;
@property (weak, nonatomic) IBOutlet UIButton *btnStop;
@property (weak, nonatomic) IBOutlet UIImageView *imgViewPublishState;
@property (weak, nonatomic) IBOutlet UIView *rightView;
@property (weak, nonatomic) IBOutlet UIView *buttomView;
@property (weak, nonatomic) IBOutlet UIView *rtcBtnsView;

@property (weak, nonatomic) IBOutlet UIButton *btnStartPublish;

@property (weak, nonatomic) IBOutlet UIButton *btnleaveRoom;
@property (weak, nonatomic) IBOutlet UIButton *btnjoinRoom;

@property (weak, nonatomic) IBOutlet UIButton *btnTouchRight;
@property (weak, nonatomic) IBOutlet UIButton *btnTouchButtom;
@property (weak, nonatomic) IBOutlet UIButton *btnTorch;
@property (weak, nonatomic) IBOutlet UILabel *lblUpload;
@property (weak, nonatomic) IBOutlet UILabel *lblDownload;
@property (weak, nonatomic) IBOutlet UITextView *lblStatus;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *rtcBtnViewBottomConstraint;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *rtcBtnViewHeightConstraint;

@property (strong, nonatomic) NSTimer *speedTimer;
@property (strong, nonatomic) NetworkInfo *network;

@property (strong, nonatomic) UIView *maskView;
@property (strong, nonatomic) ZJLogTextView *logView;

@property (strong, nonatomic) CameraServer *ucdLiveEngine;
@property (strong, nonatomic) NSMutableArray  *filterValues;
@property (strong, nonatomic) FilterManager   *filterManager;

@property (strong, nonatomic) NSTimer *timer;
@property (strong, nonatomic) NSDateFormatter *dateFormatter;
@property (strong, nonatomic) UIAlertView *alert;
@property (strong, nonatomic) UIAlertController *alertController;

@property UCDAgoraServiceKit * kit;
@property (nonatomic, assign) BOOL bExitFlag;

@property (weak, nonatomic) IBOutlet NSLayoutConstraint *viewWidth;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *secondViewLeading;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *btnStopWidth;

- (IBAction)btnStopTouchUpInside:(id)sender;
- (IBAction)btnStartLiveTouchUpInside:(id)sender;
- (IBAction)btnMuteTouchUpInside:(id)sender;
- (IBAction)btnMultiVoiceTouchUpInside:(id)sender;
- (IBAction)btnMirrorTouchUpInside:(id)sender;
- (IBAction)btnChangeCaptureTouchUpInside:(id)sender;
- (IBAction)btnFilterTouchUpInside:(id)sender;
- (IBAction)btnFilterSettingTouchUpInside:(id)sender;
- (IBAction)btnRTCTouchUpInside:(id)sender;
- (IBAction)btnLogTouchUpInside:(id)sender;
- (IBAction)btnTouchButtomTouchUpInside:(id)sender;
- (IBAction)btnTouchRightTouchUpInside:(id)sender;
- (IBAction)btnJoinnalRoomTouchUpInside:(id)sender;
- (IBAction)btnLeaveRoomTouchUpInside:(id)sender;
- (IBAction)tap:(id)sender;

@end

@implementation RTCLiveViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view from its nib.
    
    isFirstStream = YES;
    _dateFormatter = [[NSDateFormatter alloc] init];
    [_dateFormatter setDateFormat:@"mm:ss"];
    
    [self.view addSubview:self.maskView];
    //add log view
    _logView = [ZJLogTextView addDebugViewWithAlpha:1.0];
    _logView.publishUrl = _publishUrl;
    
    _btnleaveRoom.enabled = NO;
    //initial UCDLiveEngine cameraServer
    _ucdLiveEngine = [CameraServer server];
    _ucdLiveEngine.videoOrientation = UCloudVideoOrientationPortrait;
    
    _kit = [[UCDAgoraServiceKit alloc] initWithDefaultConfig];
    _rtcBtnViewBottomConstraint.constant = -_rtcBtnViewHeightConstraint.constant - _buttomView.frame.size.height;
    
    self.filterManager = [[FilterManager alloc] init];
    liveFilters = [self.filterManager filters];
    _kit.curfilter = liveFilters[0];
    //设置rtc参数
    [self setAgoraServiceKitConfiguration];
    if (_kit) {
        // init with default filter
        _kit.curfilter = liveFilters[0];
    }
    
    //bengin camera capture
    [self startLive];
    
    //设置拖拽手势
    UIPanGestureRecognizer *panGestureRecognizer = [[UIPanGestureRecognizer alloc]initWithTarget:self action:@selector(panAction:)];
    UITapGestureRecognizer *tapGestureRecognizer = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(tapAction:)];
    tapGestureRecognizer.numberOfTapsRequired = 2;
    
    CGRect rect;
    rect.origin.x = _kit.winRect.origin.x * self.view.frame.size.width;
    rect.origin.y = _kit.winRect.origin.y * self.view.frame.size.height;
    rect.size.height =_kit.winRect.size.height * self.view.frame.size.height;
    rect.size.width =_kit.winRect.size.width * self.view.frame.size.width;
    
    UIView *_winRtcView =  [[UIView alloc] initWithFrame:rect];
    _winRtcView.backgroundColor = [UIColor clearColor];
    [self.view addSubview:_winRtcView];
    [self.view bringSubviewToFront:_winRtcView];
    [_winRtcView addGestureRecognizer:panGestureRecognizer];
    [_winRtcView addGestureRecognizer:tapGestureRecognizer];
    
    if([_ucdLiveEngine currentCapturePosition] == AVCaptureDevicePositionBack){
        self.btnTorch.enabled = YES;
    } else {
        self.btnTorch.enabled = NO;
        if (self.btnTorch.selected) {
            self.btnTorch.selected = NO;
        }
    }
    
    if (self.rtcRole == Role_VICE_Anchor) {

        self.btnStartPublish.enabled = NO;
    }
    else
    {
        self.btnStartPublish.enabled = YES;
    }
}

//更新约束
- (void)updateViewConstraints {
    [super updateViewConstraints];
    //设置为两个屏幕的宽度
    self.viewWidth.constant = CGRectGetWidth([UIScreen mainScreen].bounds) * 2;
    self.secondViewLeading.constant = CGRectGetWidth([UIScreen mainScreen].bounds);
    self.btnStopWidth.constant = CGRectGetWidth([UIScreen mainScreen].bounds) / 4;
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

/*
 #pragma mark - Navigation
 
 // In a storyboard-based application, you will often want to do a little preparation before navigation
 - (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
 // Get the new view controller using [segue destinationViewController].
 // Pass the selected object to the new view controller.
 }
 */

#pragma mark - 直播
- (void)startLive
{
    if (TARGET_IPHONE_SIMULATOR) {
        NSLog(@"Can't publish stream in simulator,please use iphone or ipad!");
        return;
    }
    
    [UIApplication sharedApplication].idleTimerDisabled = YES;
    _ucdLiveEngine.width = 640;
    _ucdLiveEngine.height = 360;
    _ucdLiveEngine.fps = 15;
    
    _ucdLiveEngine.secretKey = AccessKey;
    _ucdLiveEngine.bitrate = UCloudVideoBitrateMedium;
    
    _ucdLiveEngine.logLevel = (UCDLiveLogLevelInfo);
    __weak RTCLiveViewController *weakSelf = self;
    [_ucdLiveEngine configureCameraWithOutputUrl:_publishUrl filter:liveFilters messageCallBack:^(UCloudCameraCode code, NSInteger arg1, NSInteger arg2, id data) {
        
        [weakSelf handlerMessageCallBackWithCode:code arg1:arg1 arg2:arg2 data:data weakSelf:weakSelf];
    } deviceBlock:^(AVCaptureDevice *dev) {
        
        [self handlerDeviceBlock:dev weakSelf:weakSelf];
    } cameraData:^CVPixelBufferRef(CVPixelBufferRef buffer) {
        //如果不需要裸流，不建议在这里执行操作，将增加额外的功耗
        return nil;
    }];
}

- (void)handlerMessageCallBackWithCode:(UCloudCameraCode)code arg1:(NSInteger)arg1 arg2:(NSInteger)arg2 data:(id)data weakSelf:(RTCLiveViewController *)weakSelf
{
    [[NSNotificationCenter defaultCenter] postNotificationName:@"UCloudCameraStateUpdateNotification" object:@{@"state": @(code)}];
    NSString *codeStr = [NSString stringWithFormat:@"%ld",(unsigned long)code];
    NSLog(@"state:%@", [codeStr cameraCodeToMessage]);
    [weakSelf status:[NSString stringWithFormat:@"rtmpSt:%@",[codeStr cameraCodeToMessage]]];
    
    if (code == UCloudCamera_Permission) {
        [self showAlertTitle:@"相机授权" message:@"没有权限访问您的相机，请在“设置－隐私－相机”中允许使用" tag:1];
    }
    else if (code == UCloudCamera_Micphone) {
        [self showAlertTitle:@"麦克风授权" message:@"没有权限访问您的麦克风，请在“设置－隐私－麦克风”中允许使用" tag:2];
    }
    else if (code == UCloudCamera_SecretkeyNil) {
        [self showAlertTitle:@"Warning" message:@"密钥为空" tag:3];
    }
    else if (code == UCloudCamera_AuthFail) {
        NSLog(@"鉴权失败\n");
        [self showAlertTitle:@"Warning" message:@"鉴权失败,请查证您的AccessKey" tag:4];
    }
    else if (code == UCloudCamera_PreviewOK) {
        [weakSelf startPreview];
        [_ucdLiveEngine cameraPrepare];
    }
    else if (code == UCloudCamera_PublishOk) {
//        [_ucdLiveEngine cameraStart];
    }
    else if (code == UCloudCamera_StartPublish) {
    }
    else if (code == UCloudCamera_OUTPUT_ERROR) {
    }
    else if (code == UCloudCamera_BUFFER_OVERFLOW) {
        
    }
}

- (void)handlerDeviceBlock:(AVCaptureDevice *)dev weakSelf:(UIViewController *)weakSelf
{
    
}

- (void) startPreview
{
    UIView *cameraView = [_ucdLiveEngine getCameraView];
    cameraView.backgroundColor = [UIColor whiteColor];
    [self.sdlView addSubview:cameraView];
    [self.sdlView sendSubviewToBack:cameraView];
    self.videoView = cameraView;
}

#pragma mark - 连麦配置
- (void)setAgoraServiceKitConfiguration
{
    _kit.selfInFront = NO;
    _kit.agoraKit.videoProfile = AgoraRtc_VideoProfile_DEFAULT;
    //设置第一小窗口属性，双人连麦
    _kit.winRect = CGRectMake(0.6f, 0.6f, 0.3f, 0.3f);//设置小窗口属性
    _kit.rtcLayer = 1;//设置小窗口图层，设置为1
    
    //设置第二小窗口的属性，适用于三人连麦，四人连麦依次可在kit中添加属性和设置
    _kit.winFansRect = CGRectMake(0.1, 0.6, 0.3, 0.3);
    _kit.rtcFansLayer = 2;
    
    //为第一小窗口增加圆角
    _kit.maskPicture = [[UCloudGPUImagePicture alloc] initWithImage:[UIImage imageNamed:@"rtcMask.png"]];
    
    __weak RTCLiveViewController *weak_demo = self;
    //kit回调，（option）
    _kit.onCallStart =^(int status){
        if(status == 200)
        {
            if([UIApplication sharedApplication].applicationState !=UIApplicationStateBackground)
            {
                NSLog(@"建立连接");
                [weak_demo status:@"rtcSt:与他人建立连麦"];
            }
        }
        NSLog(@"oncallstart:%d",status);
    };
    _kit.onCallStop = ^(int status){
        if(status == 200)
        {
            if([UIApplication sharedApplication].applicationState !=UIApplicationStateBackground)
            {
                NSLog(@"断开连接");
                [weak_demo status:@"rtcSt:离开房间成功"];
            }
        }
        [weak_demo cancelMonitorPublishState];
        NSLog(@"oncallstop:%d",status);
    };
    _kit.onChannelJoin = ^(int status){
        if(status == 200)
        {
            if([UIApplication sharedApplication].applicationState !=UIApplicationStateBackground)
            {
                NSLog(@"成功加入");
                [weak_demo status:@"rtcSt:进入房间成功"];
            }
        }
        NSLog(@"onChannelJoin:%d",status);
        
        [weak_demo monitorPublishState];
    };
}

-(void)onJoinChannelBtn
{
    [_kit joinChannel:_roomId];
    
}

-(void)onLeaveChannelBtn
{
    [_kit leaveChannel];
}

- (void) onQuit{
    
    _kit.bFiltering = NO;
    _kit.bExitFlag = YES;
    [_kit leaveChannel];
    _kit = nil;
    [_ucdLiveEngine shutdown:nil];
    
}

#pragma mark - UIButton Event

- (IBAction)btnStopTouchUpInside:(id)sender
{
    //取消监听
    [self cancelMonitorPublishState];
    [UIApplication sharedApplication].idleTimerDisabled = NO;
    
    __weak RTCLiveViewController *weakSelf = self;
    [_ucdLiveEngine shutdown:^{
        if (weakSelf.videoView) {
            [weakSelf.videoView removeFromSuperview];
        }
        weakSelf.videoView = nil;
        
    }];
    
    [self onQuit];
    [self.navigationController popViewControllerAnimated:YES];
}

- (IBAction)btnStartLiveTouchUpInside:(id)sender {
    
    UIButton *btn = (UIButton *)sender;
    if (btn.selected) {
        btn.selected = NO;
        [_ucdLiveEngine cameraStopPublish];
    } else {
        btn.selected = YES;
        if (isFirstStream) {
            isFirstStream = NO;
            [_ucdLiveEngine cameraStart];
            //监听发送状态
            [self monitorPublishState];
        } else {
            [_ucdLiveEngine cameraResumePublish];
        }

        
    }
    
}

- (IBAction)btnMuteTouchUpInside:(id)sender {
    
    UIButton *btn = (UIButton *)sender;
    _ucdLiveEngine.muted = !_ucdLiveEngine.muted;
    btn.selected = [CameraServer server].muted;
}

- (IBAction)btnMultiVoiceTouchUpInside:(id)sender {
    UIButton *btnMixAudio = (UIButton *)sender;
    if (btnMixAudio.selected) {
        btnMixAudio.selected = NO;
    }
    else {
        btnMixAudio.selected = YES;
    }
    
    NSURL *audioUrl   = [[NSBundle mainBundle] URLForResource: @"audioMixTest"
                                                withExtension: @"mp3"];
    NSString *audioPathStr = [audioUrl path];
    _ucdLiveEngine.audioPlayStr = audioPathStr;
    _ucdLiveEngine.backgroudMusicOn = !_ucdLiveEngine.backgroudMusicOn;
}

- (IBAction)btnMirrorTouchUpInside:(id)sender {
    
    UIButton *btnMirror = (UIButton *)sender;
    if (btnMirror.selected) {
        btnMirror.selected = NO;
    }
    else {
        btnMirror.selected = YES;
    }
    _ucdLiveEngine.streamMirrorFrontFacing = !_ucdLiveEngine.streamMirrorFrontFacing;
    _kit.bMirror = _ucdLiveEngine.streamMirrorFrontFacing;
}

- (IBAction)btnChangeCaptureTouchUpInside:(id)sender {
    
    [_ucdLiveEngine changeCamera];
    
    if([_ucdLiveEngine currentCapturePosition] == AVCaptureDevicePositionBack){
        self.btnTorch.enabled = YES;
    } else {
        self.btnTorch.enabled = NO;
        if (self.btnTorch.selected) {
            self.btnTorch.selected = NO;
        }
    }
    _kit.bFiltering = NO;
    [_kit setupRtcFilter:_kit.curfilter];
}

- (IBAction)btnTorchTouchUpInside:(id)sender {
    
    UIButton *btnTorch = (UIButton *)sender;
    if (btnTorch.selected) {
        btnTorch.selected = NO;
        [[CameraServer server] setTorchState:UCloudCameraCode_Off];
    }
    else {
        btnTorch.selected = YES;
        [[CameraServer server] setTorchState:UCloudCameraCode_On];
    }
}

- (IBAction)btnFilterTouchUpInside:(id)sender {
    
    _kit.bFiltering = YES;
    UIButton *btnFilter = (UIButton *)sender;
    if (btnFilter.selected) {
        btnFilter.selected = NO;
        [_ucdLiveEngine closeFilter];
        [_kit setupRtcFilter:nil];
    }
    else {
        btnFilter.selected = YES;
        liveFilters = [self.filterManager filters];
        [_ucdLiveEngine openFilter];
        [_kit setupRtcFilter:liveFilters[0]];
    }
}

- (IBAction)btnFilterSettingTouchUpInside:(id)sender
{
    FilterManager *filterManager = [[FilterManager alloc]init];
    self.filterValues = [filterManager buildData];
    NSDictionary *smoothInfo = _filterValues[0];
    CGFloat smooth = [smoothInfo[@"current"] floatValue];
    
    NSDictionary *brightnessInfo = _filterValues[1];
    CGFloat brightness  = [brightnessInfo[@"current"] floatValue];
    
    NSDictionary *saturationInfo = _filterValues[2];
    CGFloat saturation  = [saturationInfo[@"current"] floatValue];
    
    NSDictionary *sceneInfo = _filterValues[3];
    CGFloat intensity  = [sceneInfo[@"current"] floatValue];
    
    PopoverAction *actionSmooth = [PopoverAction actionWithTitle:@"磨  皮" slider:smooth handler:^(PopoverAction *action) {
        NSDictionary *info = self.filterValues[0];
        NSMutableDictionary *mutableInfo = [NSMutableDictionary dictionaryWithDictionary:info];
        mutableInfo[@"current"] = @(action.sliderValue);
        [self.filterValues replaceObjectAtIndex:[self.filterValues indexOfObject:info] withObject:mutableInfo];
        
        NSString *name = info[@"type"];
        float a = action.sliderValue;
        [self.filterManager valueChange:name value:a];
    }];
    PopoverAction *action2 = [PopoverAction actionWithTitle:@"亮  度" slider:brightness handler:^(PopoverAction *action) {
        NSDictionary *info = self.filterValues[1];
        NSMutableDictionary *mutableInfo = [NSMutableDictionary dictionaryWithDictionary:info];
        mutableInfo[@"current"] = @(action.sliderValue);
        [self.filterValues replaceObjectAtIndex:[self.filterValues indexOfObject:info] withObject:mutableInfo];
        
        NSString *name = info[@"type"];
        float a = action.sliderValue;
        [self.filterManager valueChange:name value:a];
    }];
    PopoverAction *action3 = [PopoverAction actionWithTitle:@"色 调" slider:saturation handler:^(PopoverAction *action) {
        NSDictionary *info = self.filterValues[2];
        NSMutableDictionary *mutableInfo = [NSMutableDictionary dictionaryWithDictionary:info];
        mutableInfo[@"current"] = @(action.sliderValue);
        [self.filterValues replaceObjectAtIndex:[self.filterValues indexOfObject:info] withObject:mutableInfo];
        
        NSString *name = info[@"type"];
        float a = action.sliderValue;
        [self.filterManager valueChange:name value:a];
    }];
    
    PopoverAction *action4 = [PopoverAction actionWithTitle:@"场 景" slider:intensity handler:^(PopoverAction *action) {
        NSDictionary *info = self.filterValues[3];
        NSMutableDictionary *mutableInfo = [NSMutableDictionary dictionaryWithDictionary:info];
        mutableInfo[@"current"] = @(action.sliderValue);
        [self.filterValues replaceObjectAtIndex:[self.filterValues indexOfObject:info] withObject:mutableInfo];
        
        NSString *name = info[@"type"];
        float a = action.sliderValue;
        [self.filterManager valueChange:name value:a];
    }];
    
    PopoverView *popoverView = [PopoverView popoverView];
    popoverView.style = PopoverViewStyleDark;
    // 在没有系统控件的情况下调用可以使用显示在指定的点坐标的方法弹出菜单控件.
    
    CGRect frame = _buttomView.frame;
    [popoverView showToPoint:CGPointMake(frame.size.height / 8, frame.origin.y) withActions:@[actionSmooth, action2, action3, action4]];
}

- (IBAction)btnRTCTouchUpInside:(id)sender {
    
    dispatch_async(dispatch_get_main_queue(), ^{
        if (_rtcBtnViewBottomConstraint.constant == 0) {
            _rtcBtnViewBottomConstraint.constant = -_rtcBtnViewHeightConstraint.constant - _buttomView.frame.size.height;
        } else {
            _rtcBtnViewBottomConstraint.constant = 0;
        }
        [self viewDidLayoutSubviews];
    });
}

- (IBAction)btnLogTouchUpInside:(id)sender {
    if (_logView.hidden) {
        [_logView showDebugView];
    } else {
        [_logView dismissDebugView];
    }
    
    
}

- (IBAction)btnTouchButtomTouchUpInside:(id)sender {
    
    _btnTouchButtom.selected = !_btnTouchButtom.selected;
    if (!_btnTouchButtom.selected) {
        [UIView animateWithDuration:0.25 animations:^{
            CGRect buttomFrame = self.buttomView.frame;
            buttomFrame.origin.y = CGRectGetHeight(self.view.frame) - CGRectGetHeight(buttomFrame);
            self.buttomView.frame = buttomFrame;
            
            CGRect btnButtomFrame = self.btnTouchButtom.frame;
            btnButtomFrame.origin.y = CGRectGetHeight(self.view.frame) - CGRectGetHeight(buttomFrame) - CGRectGetHeight(btnButtomFrame);
            self.btnTouchButtom.frame = btnButtomFrame;
        }];
    } else {
        [UIView animateWithDuration:0.25 animations:^{
            CGRect buttomFrame = self.buttomView.frame;
            buttomFrame.origin.y = CGRectGetHeight(self.view.frame);
            self.buttomView.frame = buttomFrame;
            
            CGRect btnButtomFrame = self.btnTouchButtom.frame;
            btnButtomFrame.origin.y = CGRectGetHeight(self.view.frame) - CGRectGetHeight(btnButtomFrame);
            self.btnTouchButtom.frame = btnButtomFrame;
        }];
    }
}

- (IBAction)btnTouchRightTouchUpInside:(id)sender {
    
    _btnTouchRight.selected = !_btnTouchRight.selected;
    if (!_btnTouchRight.selected) {
        [UIView animateWithDuration:0.25 animations:^{
            CGRect rightFrame = self.rightView.frame;
            rightFrame.size.width = 80;
            rightFrame.origin.x = CGRectGetWidth(self.view.frame) - 80;
            self.rightView.frame = rightFrame;
            
            CGRect btnRightFrame = self.btnTouchRight.frame;
            btnRightFrame.origin.x = CGRectGetWidth(self.view.frame) - CGRectGetWidth(rightFrame) - CGRectGetWidth(btnRightFrame);
            self.btnTouchRight.frame = btnRightFrame;
        }];
    } else {
        [UIView animateWithDuration:0.25 animations:^{
            CGRect rightFrame = self.rightView.frame;
            rightFrame.origin.x = CGRectGetWidth(self.view.frame);
            rightFrame.size.width = 0;
            self.rightView.frame = rightFrame;
            
            CGRect btnRightFrame = self.btnTouchRight.frame;
            btnRightFrame.origin.x = CGRectGetWidth(self.view.frame) - CGRectGetWidth(btnRightFrame);
            self.btnTouchRight.frame = btnRightFrame;
        }];
    }
}
    
- (IBAction)btnJoinnalRoomTouchUpInside:(id)sender {
   
    _kit.bFiltering = NO;
    [self onJoinChannelBtn];
    [self adjustLayout];
    _btnjoinRoom.enabled = NO;
    _btnleaveRoom.enabled = YES;
}

- (IBAction)btnLeaveRoomTouchUpInside:(id)sender {
    
    _kit.bFiltering = NO;
    [self onLeaveChannelBtn];
    [self adjustLayout];
    _btnjoinRoom.enabled = YES;
    _btnleaveRoom.enabled = NO;
}

- (IBAction)tap:(id)sender {
    
    [self adjustLayout];
}

#pragma mark - UIGestureRecognizer
-(void)panAction:(UIPanGestureRecognizer *)panGestureRecognizer
{
    //获取手势在屏幕上拖动的点
    CGPoint translatedPoint = [panGestureRecognizer translationInView:self.view];
    
    panGestureRecognizer.view.center = CGPointMake(panGestureRecognizer.view.center.x + translatedPoint.x, panGestureRecognizer.view.center.y + translatedPoint.y);
    
    CGRect newWinRect;
    newWinRect.origin.x = (panGestureRecognizer.view.center.x - panGestureRecognizer.view.frame.size.width/2)/self.view.frame.size.width;
    newWinRect.origin.y = (panGestureRecognizer.view.center.y - panGestureRecognizer.view.frame.size.height/2)/self.view.frame.size.height;
    newWinRect.size.height = _kit.winRect.size.height;
    newWinRect.size.width = _kit.winRect.size.width;
    _kit.winRect = newWinRect;
    [panGestureRecognizer setTranslation:CGPointMake(0, 0) inView:self.view];
}

- (void)tapAction:(UITapGestureRecognizer *)tap
{
    CGPoint origin = [tap locationInView:self.view];
    CGPoint location;
    location.x = origin.x/self.view.frame.size.width;
    location.y = origin.y/self.view.frame.size.height;
    
    CGRect winrect = _kit.winRect;
    
    //点击小窗口进行切换窗口
    if((location.x > winrect.origin.x && location.x <winrect.origin.x +winrect.size.width) &&
       (location.y > winrect.origin.y && location.y <winrect.origin.y +winrect.size.height))
    {
        _kit.selfInFront = !_kit.selfInFront;
    }
}


#pragma mark - 私有方法
- (void)adjustLayout
{
    if (_rtcBtnViewBottomConstraint.constant == 0) {
        _rtcBtnViewBottomConstraint.constant = -_rtcBtnViewHeightConstraint.constant;
    } else {
        _rtcBtnViewBottomConstraint.constant = 0;
    }
    [self viewDidLayoutSubviews];
}

-(void)status:(NSString *)status
{
    dispatch_async(dispatch_get_main_queue(), ^{
        NSDate *date = [NSDate date];
        NSString *text = [NSString stringWithFormat:@"\n%@ %@", [_dateFormatter stringFromDate:date],status];
        self.lblStatus.text = [text stringByAppendingString:self.lblStatus.text];
        
    });
}

- (void)monitorPublishState
{
    if (_timer) {
        return;
    }
    
    _timer = [NSTimer scheduledTimerWithTimeInterval:1.0
                                              target:self
                                            selector:@selector(changeImage)
                                            userInfo:nil
                                             repeats:YES];
}

- (void)cancelMonitorPublishState
{
    [_timer invalidate];
    _timer = nil;
}

- (void)changeImage
{
    float avg = [[_ucdLiveEngine outBitrate] floatValue];
    float range = 41;
    if (avg > UCloudVideoBitrateMedium)
    {
        avg = UCloudVideoBitrateMedium;
    }
    float decibels = avg / UCloudVideoBitrateMedium * range;
    CGRect frame = _imgViewPublishState.frame;
    frame.size.height = decibels;
    self.maskView.frame = frame;
    
    _maskView.layer.frame = CGRectMake(0,
                                       _imgViewPublishState.frame.size.height - decibels,
                                       _imgViewPublishState.frame.size.width,
                                       _imgViewPublishState.frame.size.height);
    if (decibels == 0.00) {
        _maskView.layer.frame = CGRectMake(0,
                                           0,
                                           _imgViewPublishState.frame.size.width,
                                           _imgViewPublishState.frame.size.height);
    }
    
    [_imgViewPublishState.layer setMask:_maskView.layer];
    
    if (decibels/range > 0.66) {
        _imgViewPublishState.tintColor = [UIColor greenColor];
    } else if (decibels/range > 0.33) {
        _imgViewPublishState.tintColor = [UIColor yellowColor];
    } else if (decibels/range > 0.01) {
        _imgViewPublishState.tintColor = [UIColor redColor];
    }
    
    if (!_network) {
        _network = [[NetworkInfo alloc]init];
    }
    [_network update];
    
    if (_network.upSpeed / 1024 / 1024 > 1) {
        _lblUpload.text = [NSString stringWithFormat:@"%.1f MB/s", _network.upSpeed / 1024 / 1024];
    } else {
        _lblUpload.text = [NSString stringWithFormat:@"%.1f KB/s", _network.upSpeed / 1024];
    }
    
    if (_network.downSpeed / 1024 / 1024 > 1) {
        _lblDownload.text = [NSString stringWithFormat:@"%.1f MB/s", _network.downSpeed / 1024 / 1024];
    } else {
        _lblDownload.text = [NSString stringWithFormat:@"%.1f KB/s", _network.downSpeed / 1024];
    }
}

- (void)showAlertTitle:(NSString *)title message:(NSString *)message tag:(NSInteger)tag
{
    if (USystem_Version < 9.0) {
        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:title
                                                        message:message
                                                       delegate:nil
                                              cancelButtonTitle:@"取消"
                                              otherButtonTitles:@"确定", nil];
        alert.tag = tag;
        alert.delegate = self;
        [alert show];
    } else {
        UIAlertController *alertController = [UIAlertController alertControllerWithTitle:title
                                                                                 message:message
                                                                          preferredStyle:UIAlertControllerStyleAlert];
        UIAlertAction *cancelAction = [UIAlertAction actionWithTitle:@"取消"
                                                               style:UIAlertActionStyleCancel
                                                             handler:nil];
        UIAlertAction *okAction = [UIAlertAction actionWithTitle:@"确定"
                                                           style:UIAlertActionStyleDefault
                                                         handler:^(UIAlertAction * _Nonnull action) {
                                                             [self prefsSetting];
                                                         }];
        [alertController addAction:okAction];
        [alertController addAction:cancelAction];
        [self presentViewController:alertController animated:YES completion:nil];
    }
}

#pragma mark - UIAlertViewDelegate
- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex
{
    if ((alertView.tag == 1 || alertView.tag == 2) && buttonIndex == 0) {
        [self prefsSetting];
    }
}


- (void)prefsSetting
{
    NSURL *url = [NSURL URLWithString:UIApplicationOpenSettingsURLString];
    
    if ([[UIApplication sharedApplication] canOpenURL:url]) {
        
        [[UIApplication sharedApplication] openURL:url];
    }
}

- (UIView *)maskView
{
    if (!_maskView)
    {
        _maskView = [[UIView alloc] initWithFrame:CGRectZero];
        _maskView.translatesAutoresizingMaskIntoConstraints = NO;
        _maskView.backgroundColor = [UIColor blueColor];
    }
    return _maskView;
}

#pragma mark - Orientation

- (BOOL)shouldAutorotate{
    //是否允许转屏
//    if (!_isPortrait) {
//        return YES;
//    }
    
    return NO;
}

- (UIInterfaceOrientationMask)supportedInterfaceOrientations
{
    //viewController所支持的全部旋转方向
//    if (!_isPortrait) {
//        return UIInterfaceOrientationMaskLandscapeRight;
//    }
    
    return UIInterfaceOrientationMaskPortrait | UIInterfaceOrientationMaskLandscapeLeft | UIInterfaceOrientationMaskLandscapeRight;
}

- (UIInterfaceOrientation)preferredInterfaceOrientationForPresentation
{
    //viewController初始显示的方向
//    if (!_isPortrait) {
//        return UIInterfaceOrientationLandscapeRight;
//    }
    
    return UIInterfaceOrientationPortrait;
}


@end
