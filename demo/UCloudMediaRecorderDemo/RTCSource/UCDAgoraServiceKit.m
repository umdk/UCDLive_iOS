//
//  UCDAgoraServiceKit.m
//  UCloudMediaRecorderDemo
//
//  Created by Sidney on 6/13/17.
//  Copyright © 2017 https://UCloud.cn. All rights reserved.

#import "UCDAgoraClient.h"
#import "UCloudGPUImage.h"
#import "UCDAgoraServiceKit.h"
#import "CameraServer.h"
#import <mach/mach_time.h>

typedef void(^videoPreviewMixerBlock)(UCloudGPUImageOutput *output, CMTime timeinfo);

typedef void(^videoOutputBlock)(CVPixelBufferRef pixelBuffer, CMTime timeInfo);

@interface UCDAgoraServiceKit()<AgoraRtcEngineDelegate>

@property (assign, nonatomic) AVCaptureDevicePosition devCurentPosition;
@property (strong, nonatomic) UCloudGPUImageUIElement *uiElementInput;
@property (strong, nonatomic) UCloudGPUImageMaskFilter *maskingFilter;
@property (strong, nonatomic) UCloudGPUImageFilter *maskingShieldFilter;//用于mask隔离，防止残影发生
@property (assign, nonatomic) CMTime videoPts;
@property (strong, nonatomic) CameraServer *liveEngine;
@property (strong, nonatomic) UCloudGPUVideoMixer *videoPreviewMixer;
@property (strong, nonatomic) UCloudGPUVideoMixer *videoRtmpMixer;
@property (strong, nonatomic) UCloudGPUVideoOutput *videoOutput;
@property (strong, nonatomic) UCloudGPUVideoOutput *beautyOutput;
@property (strong, nonatomic) UCloudGPUImageVideoInput  *rtcVideoInput;
@property (copy,   nonatomic) videoPreviewMixerBlock    videoPreviewMixerCallback;
@property (copy,   nonatomic) videoOutputBlock   videoOutputCallback;
@property (nonatomic, strong) UCloudGPUImageOutput<UCloudGPUImageInput> *filter;

@end

@implementation UCDAgoraServiceKit

/**
 @abstract 初始化方法
 @discussion 创建带有默认参数的 kit
 @warning kit只支持单实例推流，构造多个实例会出现异常
 */
- (instancetype)initWithDefaultConfig
{
    __weak typeof(self) weakSelf = self;
    NSAssert(RTCAPPid.length>1, @"请发邮件至spt_sdk@ucloud.cn或联系客服、客户经理索取对应的APPID");
    _agoraKit = [[UCDAgoraClient alloc] initWithAppId:RTCAPPid delegate:weakSelf];
    _beautyOutput = nil;
    _callstarted = NO;
    _maskPicture = nil;
    _maskingShieldFilter = [[UCloudGPUImageFilter alloc]init];
    _contentView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, [UIScreen mainScreen].bounds.size.width,[UIScreen mainScreen].bounds.size.height)];
    _contentView.backgroundColor = [UIColor clearColor];
    _curfilter = self.filter;
    self.cameraLayer = 0;
    
    _videoPreviewMixer = [[UCloudGPUVideoMixer alloc]init];
    
    _videoOutput = [[UCloudGPUVideoOutput alloc] init];
    _videoRtmpMixer = [[UCloudGPUVideoMixer alloc]init];
   
    self.videoPreviewMixerCallback = ^(UCloudGPUImageOutput *output, CMTime timeinfo) {
        UCloudGPUImageFramebuffer *imageFramebuffer = output.framebufferForOutput;
        CVPixelBufferRef pixelBuffer = [imageFramebuffer pixelBuffer];
        [weakSelf.liveEngine pushPixelBuffer:pixelBuffer completion:nil];
    };
    self.videoOutputCallback = ^(CVPixelBufferRef pixelBuffer, CMTime timeInfo){
        [weakSelf.liveEngine pushPixelBuffer:pixelBuffer completion:nil];
    };
    
//    self.videoProcessingCallback = ^(CMSampleBufferRef buf){
//        weakSelf.videoPts= CMSampleBufferGetPresentationTimeStamp(buf);
//    };

    _liveEngine = [CameraServer server];
    self.devCurentPosition = _liveEngine.captureDevicePos;
    
    __weak UCDAgoraServiceKit * weak_kit = self;
    // 加入channel成功回调,开始发送数据
    _agoraKit.joinChannelBlock = ^(NSString* channel, NSUInteger uid, NSInteger elapsed){
        NSLog(@"我进了%@房间", channel);
        if (channel)
        {
            if (!weak_kit.beautyOutput)
            {
                [weak_kit setupBeautyOutput];
                [weak_kit setupRtcFilter:weak_kit.curfilter];
            }
            
            if (weak_kit.onChannelJoin)
                weak_kit.onChannelJoin(200);
        }
    };
    // 离开channel成功回调
    _agoraKit.leaveChannelBlock = ^(AgoraRtcStats* stat){
        NSLog(@"local leave channel");
        NSLog(@"我离开了");
        if (weak_kit.callstarted) {
            [weak_kit stopRTCView];
             weak_kit.callstarted = NO;
        }
        
        if (!weak_kit.bExitFlag) {
            [weak_kit.liveEngine startAudioModule];
        }
        
        if(weak_kit.onCallStop)
            weak_kit.onCallStop(200);
    };
    
    // 接收数据回调，放入videoinput里面
    _agoraKit.videoDataCallback=^(CVPixelBufferRef buf){
//        NSLog(@"remote data");
        [weak_kit defaultRtcVideoCallback:buf];
    };
    
    // 对方音频回调
    _agoraKit.remoteAudioDataCallback=^(void* buffer,int sampleRate,int len,int bytesPerSample,int channels,int64_t pts)
    {
        if (weak_kit.callstarted) {
            [weak_kit.liveEngine mixerAudioDataInBus:1 AudioData:[NSData  dataWithBytes:buffer length:len]];
        }
    };
    // 本地音频回调
    _agoraKit.localAudioDataCallback=^(void* buffer,int sampleRate,int len,int bytesPerSample,int channels,int64_t pts)
    {
        [weak_kit.liveEngine mixerAudioDataInBus:0 AudioData:[NSData dataWithBytes:buffer length:len]];
    };

    //注册进入后台的处理
    NSNotificationCenter* dc = [NSNotificationCenter defaultCenter];
    
    [dc addObserver:self
           selector:@selector(becomeActive)
               name:UIApplicationDidBecomeActiveNotification
             object:nil];
    
    [dc addObserver:self
           selector:@selector(resignActive)
               name:UIApplicationWillResignActiveNotification
             object:nil];
    
    
//    [dc addObserver:self
//           selector:@selector(interruptHandler:)
//               name:AVAudioSessionInterruptionNotification
//             object:nil];

    
    return self;
}

//- (void)interruptHandler:(NSNotification *)notification {
//    UInt32 interruptionState = [notification.userInfo[AVAudioSessionInterruptionTypeKey] unsignedIntValue];
//    if (interruptionState == kAudioSessionBeginInterruption){
//        if(_callstarted){
//            [self stopRTCView];
//            _callstarted = NO;
//        }
//    }
//    else if (interruptionState == kAudioSessionEndInterruption){
//        if(!_callstarted){
//            [self startRtcView];
//            _callstarted = YES;
//        }
//    }
//}

- (instancetype)init {
    return [self initWithDefaultConfig];
}
- (void)dealloc {
    NSLog(@"kit dealloc ");
    if (_agoraKit) {
        [_agoraKit leaveChannel];
        _agoraKit = nil;
    }
    
    if (_beautyOutput) {
        _beautyOutput = nil;
    }
    
    if (_rtcVideoInput) {
        _rtcVideoInput = nil;
    }
    
    if (_contentView)
    {
        _contentView = nil;
    }
    
    NSNotificationCenter* dc = [NSNotificationCenter defaultCenter];
    [dc removeObserver:self
                  name:AVAudioSessionInterruptionNotification
                object:nil];
    [dc removeObserver:self
                  name:UIApplicationDidBecomeActiveNotification
                object:nil];
//    [dc removeObserver:self
//                  name:UIApplicationWillResignActiveNotification
//                object:nil];
}


- (void)setBMirror:(BOOL)bMirror
{
    _bMirror = bMirror;
    
    if (AVCaptureDevicePositionFront == self.liveEngine.captureDevicePos) {
        
        if (bMirror) {
            // 设置镜像
            [self.videoPreviewMixer setVideoRotation:kUCloudGPUImageFlipHorizonal ofLayer:0];
        }
        else
        {
            [self.videoPreviewMixer setVideoRotation:kUCloudGPUImageNoRotation ofLayer:0];
        }
        
    }
    
}



- (void)setupRtcFilter:(UCloudGPUImageOutput<UCloudGPUImageInput> *)filter {
    
    _curfilter = filter;
    _filter = filter;
    if (_liveEngine.videoCamera == nil) {
        return;
    }
    // 采集的图像先经过前处理
    [_liveEngine.videoCamera removeAllTargets];
    UCloudGPUImageOutput *src = _liveEngine.videoCamera;
    
    if (filter)
    {
        [self.filter removeAllTargets];
        [src addTarget:self.filter];
        UCloudGPUImageEmptyFilter *emptyF = [[UCloudGPUImageEmptyFilter alloc]init];
        [self.filter addTarget:emptyF];
        src = emptyF;
    }
    else
    {
        UCloudGPUImageFilter* nFilter = [[UCloudGPUImageFilter alloc]init];
        [src addTarget:nFilter];
        src = nFilter;
    }
    
    // 组装图层
    if (_rtcVideoInput)
    {
       if (!self.bFiltering) {
            [_rtcVideoInput removeAllTargets];
        }
        if (!_selfInFront)//主播
        {
            [self setMixerMasterLayer:_cameraLayer];
            [self addInput:src ToMixerAt:_cameraLayer];
            if (!self.bFiltering) {
                if (_maskPicture) {
                    [self Maskwith:_rtcVideoInput];
                    [self addInput:_maskingFilter ToMixerAt:_rtcLayer Rect:_winRect];
                } else {
                    [self addInput:_rtcVideoInput ToMixerAt:_rtcLayer Rect:_winRect];
                }
            }
            
        }
        else{//辅播
            if (!self.bFiltering) {
              [self setMixerMasterLayer:self.rtcLayer];
              [self addInput:_rtcVideoInput  ToMixerAt:_cameraLayer];
            }
            if (_maskPicture) {
                [self Maskwith:src];
                [self addInput:_maskingFilter ToMixerAt:_rtcLayer Rect:_winRect];
            } else {
                [self addInput:src ToMixerAt:_rtcLayer Rect:_winRect];
            }
        }
    } else {
        [self clearMixerLayer:_rtcLayer];
        [self clearMixerLayer:_cameraLayer];
        [self setMixerMasterLayer:_cameraLayer];
        [self addInput:src ToMixerAt:_cameraLayer];
    }
    
    //美颜后的图像，用于rtc发送
    if(_beautyOutput)
    {
        [src addTarget:_beautyOutput];
        // [_liveEngine.videoCamera addTarget:_beautyOutput];
        if (AVCaptureDevicePositionFront == self.liveEngine.captureDevicePos) {
            
            [_beautyOutput setInputRotation:kUCloudGPUImageFlipHorizonal atIndex:0];
            
        }
        else
        {
            [_beautyOutput setInputRotation:kUCloudGPUImageNoRotation atIndex:0];
        }
        
    }
    
    //组装自定义view
//    if(_uiElementInput){
//        [self addElementInput:_uiElementInput callbackOutput:src];
//    }
//    else{
//        [self removeElementInput:_uiElementInput callbackOutput:src];
//    }
    
    // 混合后的图像输出到预览和推流
    [self.videoPreviewMixer removeAllTargets];
    [self.videoRtmpMixer removeAllTargets];
    [self.videoPreviewMixer addTarget:(id<UCloudGPUImageInput>)[_liveEngine getCameraView]];
    UCloudGPUImageView *previewView = (UCloudGPUImageView *)[_liveEngine getCameraView];
    
    if (AVCaptureDevicePositionFront == self.liveEngine.captureDevicePos) {
        
        if (self.devCurentPosition != AVCaptureDevicePositionFront) {
            
            self.devCurentPosition = AVCaptureDevicePositionFront;
            self.rtcVideoInput.internalRotation = kUCloudGPUImageNoRotation;
            [self.videoPreviewMixer setVideoRotation:kUCloudGPUImageNoRotation ofLayer:1];
            [self.videoRtmpMixer setVideoRotation:kUCloudGPUImageNoRotation ofLayer:0];
            [self.videoRtmpMixer setVideoRotation:kUCloudGPUImageNoRotation ofLayer:1];
        }

        
        [self.videoRtmpMixer addTarget:self.videoOutput];
        [self.videoRtmpMixer setVideoRotation:kUCloudGPUImageFlipHorizonal ofLayer:1];
//        [self.videoOutput setInputRotation:kUCloudGPUImageFlipHorizonal atIndex:0];
        _videoRtmpMixer.frameProcessingCompletionBlock  = nil;
        _videoOutput.videoProcessingCallback = self.videoOutputCallback;
        // 设置镜像
        [previewView setInputRotation:kUCloudGPUImageFlipHorizonal atIndex:0];
    }
    else
    {
        self.devCurentPosition = AVCaptureDevicePositionBack;
        self.rtcVideoInput.internalRotation = kUCloudGPUImageFlipHorizonal;
        [self.videoPreviewMixer setVideoRotation:kUCloudGPUImageFlipHorizonal ofLayer:1];
        [self.videoRtmpMixer setVideoRotation:kUCloudGPUImageFlipHorizonal ofLayer:1];
        _videoOutput.videoProcessingCallback = nil;
        _videoRtmpMixer.frameProcessingCompletionBlock = self.videoPreviewMixerCallback;
    }
    
}

-(void)addElementInput:(UCloudGPUImageUIElement *)input
         callbackOutput:(UCloudGPUImageOutput*)callbackOutput
{
    __weak UCloudGPUImageUIElement *weakUIEle = self.uiElementInput;
    [callbackOutput setFrameProcessingCompletionBlock:^(UCloudGPUImageOutput * f, CMTime fT){
        NSArray* subviews = [_contentView subviews];
        for(int i = 0;i<subviews.count;i++)
        {
            UIView* subview = (UIView*)[subviews objectAtIndex:i];
            if(subview)
                subview.hidden = NO;
        }
        if (subviews.count > 0)
        {
            [weakUIEle update];
        }
    }];
//    [self addInput:_uiElementInput ToMixerAt:_customViewLayer Rect:_customViewRect];
}

//- (void) addPic:(GPUImageOutput*)pic ToMixerAt: (NSInteger)idx{
//    if (pic == nil){
//        return;
//    }
//    [pic removeAllTargets];
//    UCDGPUPicMixer * vMixer[2] = {self.vPreviewMixer, self.vStreamMixer};
//    for (int i = 0; i<2; ++i) {
//        [vMixer[i]  clearPicOfLayer:idx];
//        [pic addTarget:vMixer[i] atTextureLocation:idx];
//    }
//}

-(void)Maskwith:(UCloudGPUImageOutput *)input
{
    [input removeAllTargets];
    [_maskPicture removeAllTargets];
    [_maskingFilter removeAllTargets];
    [_maskingShieldFilter removeAllTargets];
    
    [input addTarget:_maskingShieldFilter];
    [_maskingShieldFilter addTarget:_maskingFilter];
    [_maskPicture addTarget:_maskingFilter];
    [_maskPicture processImage];
}


-(void) setMixerMasterLayer:(NSInteger)idx
{
    UCloudGPUVideoMixer * vMixer[2] = {self.videoPreviewMixer, self.videoRtmpMixer};
    for (int i = 0; i<2; ++i) {
        [vMixer[i]  setMasterLayer:idx];
    }
}


//- (void) addPic:(GPUImageOutput*)pic
//      ToMixerAt: (NSInteger)idx
//           Rect:(CGRect)rect{
//    if (pic == nil){
//        return;
//    }
//    [pic removeAllTargets];
//    UCDGPUPicMixer * vMixer[2] = {self.vPreviewMixer, self.vStreamMixer};
//    for (int i = 0; i<2; ++i) {
//        [vMixer[i]  clearPicOfLayer:idx];
//        [pic addTarget:vMixer[i] atTextureLocation:idx];
//        [vMixer[i] setPicRect:rect ofLayer:idx];
//        [vMixer[i] setPicAlpha:1.0f ofLayer:idx];
//    }
//}


- (void)addInput:(UCloudGPUImageOutput*)pic
        ToMixerAt:(NSInteger)idx{
    if (pic == nil){
        return;
    }
    [pic removeAllTargets];
    
    UCloudGPUVideoMixer * vMixer[2] = {self.videoPreviewMixer, self.videoRtmpMixer};
    for (int i = 0; i<2; ++i) {
        [vMixer[i]  clearVideoOfLayer:idx];
        [pic addTarget:vMixer[i] atTextureLocation:idx];
    }
}


-(void) removeElementInput:(UCloudGPUImageUIElement *)input
            callbackOutput:(UCloudGPUImageOutput *)callbackOutput
{
//    [self clearMixerLayer:_customViewLayer];
    [callbackOutput setFrameProcessingCompletionBlock:nil];
}

-(void) clearMixerLayer:(NSInteger)idx
{
    UCloudGPUVideoMixer * vMixer[2] = {self.videoPreviewMixer, self.videoRtmpMixer};
    for (int i = 0; i<2; ++i) {
        [vMixer[i]  clearVideoOfLayer:idx];
    }
}


- (void) addInput:(UCloudGPUImageOutput*)pic
        ToMixerAt:(NSInteger)idx
             Rect:(CGRect)rect{
    
    [self addInput:pic ToMixerAt:idx];
    UCloudGPUVideoMixer * vMixer[2] = {self.videoPreviewMixer, self.videoRtmpMixer};
    for (int i = 0; i<2; ++i) {
        [vMixer[i] setVideoRect:rect ofLayer:idx];
        [vMixer[i] setVideoAlpha:1.0f ofLayer:idx];
    }
}


#pragma mark -rtc

-(void)joinChannel:(NSString *)channelName
{
    [self.liveEngine stopAudioModule];
    [_agoraKit joinChannel:channelName];
}

-(void)leaveChannel
{
    [_agoraKit leaveChannel];
    if (self.callstarted) {
        [self stopRTCView];
         self.callstarted = NO;
    }
}

-(void)setupBeautyOutput
{
    __weak UCDAgoraServiceKit * weak_kit = self;
    _beautyOutput  =  [[UCloudGPUVideoOutput alloc] init];
//    _beautyOutput.bCustomOutputSize = YES;
//    _beautyOutput.outputSize = [self adjustVideoProfile:_agoraKit.videoProfile];//发送size需要和videoprofile匹配
    
    _beautyOutput.videoProcessingCallback = ^(CVPixelBufferRef pixelBuffer, CMTime timeInfo ){
//        NSLog(@"send video frame to agora");
        weak_kit.videoPts = timeInfo;
        [weak_kit.agoraKit ProcessVideo:pixelBuffer timeInfo:timeInfo];
    };
}

-(void)startRtcVideoView{
    _rtcVideoInput =    [[UCloudGPUImageVideoInput alloc] init];
    if (_contentView.subviews.count != 0)
        _uiElementInput = [[UCloudGPUImageUIElement alloc] initWithView:_contentView];
    if (!_beautyOutput)
    {
        [self setupBeautyOutput];
    }
    _maskingFilter = [[UCloudGPUImageMaskFilter alloc] init];
    [self setupRtcFilter:_curfilter];
}

-(void)startRtcView
{
    [self startRtcVideoView];
}

-(void)stopRTCVideoView{
    _rtcVideoInput = nil;
    _beautyOutput = nil;
    self.liveEngine.videoProcessing = nil;
    _uiElementInput = nil;
    _maskingFilter = nil;
    [self setupRtcFilter:_curfilter];
}

-(void)stopRTCView
{
    [self stopRTCVideoView];
}

-(void) defaultRtcVideoCallback:(CVPixelBufferRef)buf
{
//    NSLog(@"width:%zu,height:%zu",CVPixelBufferGetWidth(buf),CVPixelBufferGetHeight(buf));
    
    [self.rtcVideoInput processPixelBuffer:buf time:self.videoPts];
}

-(void)setWinRect:(CGRect)rect
{
    _winRect = rect;
    if (_callstarted)
    {
        UCloudGPUVideoMixer *vMixer[2] = {self.videoPreviewMixer};
        for (int i=0; i<2; i++) {
            [vMixer[i] removeAllTargets];
            [vMixer[i] setVideoRect:rect ofLayer:self.rtcLayer];
        }
        
        [self.videoPreviewMixer addTarget:(id<UCloudGPUImageInput>)[_liveEngine getCameraView]];
        [self.videoRtmpMixer addTarget:self.videoOutput];
        [(id<UCloudGPUImageInput>)[_liveEngine getCameraView] setInputRotation:kUCloudGPUImageFlipHorizonal atIndex:0];
    }
}

-(void)setSelfInFront:(BOOL)selfInFront{
    _selfInFront = selfInFront;
    [self setupRtcFilter:_curfilter];
}

-(void)becomeActive
{
    __weak UCDAgoraServiceKit * weak_kit = self;
    _agoraKit.videoDataCallback=^(CVPixelBufferRef buf){
        [weak_kit defaultRtcVideoCallback:buf];
    };
}

-(void)resignActive
{
     _agoraKit.videoDataCallback = nil;
}


#pragma utility

-(CGSize)adjustVideoProfile:(AgoraRtcVideoProfile )videoProfile
{
    CGSize videoSize;
    switch(videoProfile){
        case AgoraRtc_VideoProfile_120P:
            videoSize=CGSizeMake(120, 160);
            break;
        case AgoraRtc_VideoProfile_120P_3:
            videoSize=CGSizeMake(120, 120);
            break;
        case AgoraRtc_VideoProfile_180P:		// 320x180   15   140
            videoSize=CGSizeMake(180, 320);
            break;
        case AgoraRtc_VideoProfile_180P_3:		// 180x180   15   100
            videoSize=CGSizeMake(180, 180);
            break;
        case AgoraRtc_VideoProfile_180P_4:		// 240x180   15   120
            videoSize=CGSizeMake(180, 240);
            break;
        case AgoraRtc_VideoProfile_240P:        // 320x240   15   200
            videoSize=CGSizeMake(240, 320);
            break;
        case AgoraRtc_VideoProfile_240P_3:		// 240x240   15   140
            videoSize=CGSizeMake(240, 240);
            break;
        case AgoraRtc_VideoProfile_240P_4:      // 424x240   15   220
            videoSize=CGSizeMake(240, 424);
            break;
        case AgoraRtc_VideoProfile_360P:
             AgoraRtc_VideoProfile_DEFAULT:// 640x360   15   400
            videoSize=CGSizeMake(360, 640);
            break;
        case AgoraRtc_VideoProfile_360P_3:	// 360x360   15   260
            videoSize=CGSizeMake(360, 360);
            break;
        case AgoraRtc_VideoProfile_360P_4:		// 640x360   30   600
            videoSize=CGSizeMake(360, 640);
            break;
        case AgoraRtc_VideoProfile_360P_6:		// 360x360   30   400
            videoSize=CGSizeMake(360, 360);
            break;
        case AgoraRtc_VideoProfile_360P_7:
        case AgoraRtc_VideoProfile_360P_8:      // 480x360   30   490
            videoSize=CGSizeMake(360, 480);
            break;
        case AgoraRtc_VideoProfile_360P_9:      // 640x360   15   800
//        case AgoraRtc_VideoProfile_360P_10:     // 640x360   24   800
//        case AgoraRtc_VideoProfile_360P_11:   // 640x360   24   1000
            videoSize=CGSizeMake(360, 640);
            break;
        case AgoraRtc_VideoProfile_480P:        	// 640x480   15   500
        case AgoraRtc_VideoProfile_480P_4:
            videoSize=CGSizeMake(480, 640);
            break;
        case AgoraRtc_VideoProfile_480P_3:		// 480x480   15   400
        case AgoraRtc_VideoProfile_480P_6:		// 480x480   30   600
            videoSize=CGSizeMake(480, 480);
            break;
        case AgoraRtc_VideoProfile_480P_8:		// 848x480   15   610
        case AgoraRtc_VideoProfile_480P_9:		// 848x480   30   930
            videoSize=CGSizeMake(480, 848);
            break;
        case AgoraRtc_VideoProfile_720P:		// 1280x720  15   1130
        case AgoraRtc_VideoProfile_720P_3:		// 1280x720  30   1710
            videoSize=CGSizeMake(720,1280);
            break;
        case AgoraRtc_VideoProfile_720P_5:		// 960x720   15   910
        case AgoraRtc_VideoProfile_720P_6:		// 960x720   30   1380
            videoSize=CGSizeMake(720,960);
            break;
        case AgoraRtc_VideoProfile_1080P:	// 1920x1080 15   2080
        case AgoraRtc_VideoProfile_1080P_3:		// 1920x1080 30   3150
        case AgoraRtc_VideoProfile_1080P_5:		// 1920x1080 60   4780
            videoSize=CGSizeMake(1080,1920);
            break;
        case AgoraRtc_VideoProfile_1440P:		// 2560x1440 30   4850
        case AgoraRtc_VideoProfile_1440P_2:		// 2560x1440 60   7350
            videoSize=CGSizeMake(1440,2560);
            break;
        case AgoraRtc_VideoProfile_4K:			// 3840x2160 30   8190
        case AgoraRtc_VideoProfile_4K_3:		// 3840x2160 60   13500
            videoSize=CGSizeMake(2160,3840);
            break;
        default:
            videoSize=CGSizeMake(360, 640);
            break;
    }
    
    return videoSize;
}

#pragma AgoraRtcEngineDelegate

- (void)rtcEngine:(AgoraRtcEngineKit *)engine didOfflineOfUid:(NSUInteger)uid reason:(AgoraRtcUserOfflineReason)reason
{
    NSLog(@"对方下线了");
    if(_callstarted){
        [self stopRTCView];
        if(_onCallStop)
            _onCallStop(reason);
        _callstarted = NO;
    }
}

- (void)rtcEngine:(AgoraRtcEngineKit *)engine didJoinedOfUid:(NSUInteger)uid elapsed:(NSInteger)elapsed
{
    NSLog(@"对方上线了");
    if(!_callstarted)
    {
        [self startRtcView];
        if(_onCallStart)
            _onCallStart(200);
        _callstarted = YES;
    }
}

- (void)rtcEngine:(AgoraRtcEngineKit *)engine didOccurError:(AgoraRtcErrorCode)errorCode
{
    NSLog(@"rtcEngine didOccurError");
}

- (void)rtcEngine:(AgoraRtcEngineKit *)engine remoteVideoStats:(AgoraRtcRemoteVideoStats*)stats
{
//    NSLog(@"remotestats,width:%lu,height:%lu,fps:%lu,receivedBitrate:%lu",(unsigned long)stats.width,(unsigned long)stats.height,(unsigned long)stats.receivedFrameRate,(unsigned long)stats.receivedBitrate);
}


@end
