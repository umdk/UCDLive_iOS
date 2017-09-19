//
//  PublishViewController.m
//  UCDLiveDemo-V2
//
//  Created by Sidney on 19/04/17.
//  Copyright © 2017年 https://ucloud.cn. All rights reserved.
//

#import "PublishViewController.h"
#import "UCDLiveDemoHeader.h"
#import "ZJLogTextView.h"
#import "PopoverView.h"
#import "NetworkInfo.h"
#import "FaceTracker.h"

#import "Global.h"
#import "KWSmiliesStickerRenderer.h"


@interface PublishViewController ()<UIAlertViewDelegate,KWSDKUIDelegate>
{
    NSArray *liveFilters;
}

@property (nonatomic, strong) GPUImageStillCamera *videoCamera;
@property (nonatomic, strong) GPUImageFilter *emptyFilter;
@property (nonatomic, strong) GPUImageUIElement   *uiElementInput;
@property (nonatomic, strong) GPUImageAlphaBlendFilter *blendFilter;
@property (nonatomic, strong) GPUImageView *previewView;
@property (nonatomic, strong) UIView        *watermarkView;
@property (nonatomic, copy  ) WatermarkBlock watermarkBlock;

@property (nonatomic, strong) CIImage *outputImage;
@property (nonatomic, assign) size_t outputWidth;
@property (nonatomic, assign) size_t outputheight;


@property (strong, nonatomic) UIView *videoView;
@property (weak, nonatomic) IBOutlet UIView *sdlView;
@property (weak, nonatomic) UIView *waterMarkView;
@property (weak, nonatomic) IBOutlet UIButton *btnStop;
@property (weak, nonatomic) IBOutlet UIImageView *imgViewPublishState;
@property (weak, nonatomic) IBOutlet UIView *rightView;
@property (weak, nonatomic) IBOutlet UIView *buttomView;
@property (weak, nonatomic) IBOutlet UIButton *btnTouchRight;
@property (weak, nonatomic) IBOutlet UIButton *btnTouchButtom;
@property (weak, nonatomic) IBOutlet UIButton *btnTorch;
@property (weak, nonatomic) IBOutlet UILabel *lblUpload;
@property (weak, nonatomic) IBOutlet UILabel *lblDownload;
    
@property (strong, nonatomic) NSTimer *speedTimer;
@property (strong, nonatomic) NetworkInfo *network;

@property (strong, nonatomic) UIView *maskView;
@property (strong, nonatomic) ZJLogTextView *logView;

@property (strong, nonatomic) CameraServer *ucdLiveEngine;
@property (strong, nonatomic) NSMutableArray  *filterValues;
@property (strong, nonatomic) FilterManager   *filterManager;

@property (strong, nonatomic) NSTimer *timer;
@property (strong, nonatomic) UIAlertView *alert;
@property (strong, nonatomic) UIAlertController *alertController;

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
- (IBAction)btnFaceUTouchUpInside:(id)sender;
- (IBAction)btnLogTouchUpInside:(id)sender;
- (IBAction)btnTouchButtomTouchUpInside:(id)sender;
- (IBAction)btnTouchRightTouchUpInside:(id)sender;


@end

@implementation PublishViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view from its nib.
    
    [self.view addSubview:self.maskView];
    
    //add log view
    _logView = [ZJLogTextView addDebugViewWithAlpha:1.0];
    _logView.publishUrl = _publishUrl;
    
    //initial UCDLiveEngine cameraServer
    _ucdLiveEngine = [CameraServer server];
    _ucdLiveEngine.isCaptureYUV = NO;
    _ucdLiveEngine.supportFilter = YES;
    _ucdLiveEngine.streamMirrorFrontFacing = NO;
    _ucdLiveEngine.videoOrientation = _direction;

    
    
    if([_ucdLiveEngine currentCapturePosition] == AVCaptureDevicePositionBack){
        self.btnTorch.enabled = YES;
    } else {
        self.btnTorch.enabled = NO;
        if (self.btnTorch.selected) {
            self.btnTorch.selected = NO;
        }
    }
    
    
    [self resetTracker];
    [self performSelector:@selector(startLive) withObject:nil afterDelay:.35];
}

- (void)resetTracker
{
    __weak typeof (self) __weakSelf = self;
    
    self.kwSdkUI = [KWSDK_UI shareManagerUI];
    
    self.kwSdkUI.delegate = self;
    
    self.kwSdkUI.kwSdk = [KWSDK sharedManager];
    
    self.kwSdkUI.kwSdk.renderer = [[KWRenderer alloc]initWithModelPath:nil];
    
    self.kwSdkUI.kwSdk.cameraPositionBack  = NO;
     _ucdLiveEngine.videoCamera = self.videoCamera;
    if([KWRenderer isSdkInitFailed]){
        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"错误提示" message:@"使用 license 文件生成激活码时失败，可能是授权文件过期。" delegate:nil cancelButtonTitle:@"好的" otherButtonTitles:nil, nil];
        
        [alert show];
        return;
    }
    
    [self.kwSdkUI setViewDelegate:self];
    
    [self.kwSdkUI.kwSdk initSdk];
    
    self.kwSdkUI.isClearOldUI = NO;
    [self.kwSdkUI setToggleBtnHidden:YES];
    [self.kwSdkUI setCloseVideoBtnHidden:NO];
    
    [self.kwSdkUI initSDKUI];
    
    self.kwSdkUI.kwSdk.videoCamera = self.videoCamera;

    self.kwSdkUI.closeVideoBtnBlock = ^()
    {
        [__weakSelf btnStopTouchUpInside:nil];
         
    };


}


//加载拍照,视频录制摄像头工具类
- (GPUImageView *)previewView
{
    if (!_previewView) {
        _previewView = [[GPUImageView alloc] initWithFrame:self.view.frame];
        _previewView.fillMode = kGPUImageFillModeStretch;
        _previewView.fillMode = kGPUImageFillModePreserveAspectRatioAndFill;
        _previewView.backgroundColor = [UIColor whiteColor];
        [self.sdlView addSubview:_previewView];
        [self.sdlView sendSubviewToBack:_previewView];
        self.videoView = _previewView;

    }
    return _previewView;
}

-(GPUImageStillCamera *)videoCamera
{
    if (!_videoCamera) {
        _videoCamera = [[GPUImageStillCamera alloc] initWithSessionPreset:AVCaptureSessionPreset640x480
                                                           cameraPosition:AVCaptureDevicePositionFront];
        _videoCamera.frameRate = 20;
        _videoCamera.outputImageOrientation = UIDeviceOrientationPortrait;
        _videoCamera.horizontallyMirrorFrontFacingCamera = YES;
        _videoCamera.horizontallyMirrorRearFacingCamera = NO;
        _videoCamera.delegate = self;
        
        [_videoCamera addTarget:self.emptyFilter];
        [self.emptyFilter addTarget:self.previewView];
        [_videoCamera startCameraCapture];
        
        [self outputPixelBuffer];
        
    }
    return _videoCamera;
}


- (GPUImageFilter *)emptyFilter
{
    if (!_emptyFilter) {
        _emptyFilter = [[GPUImageFilter alloc]init];
    }
    return _emptyFilter;
}


- (GPUImageUIElement *)uiElementInput{
    if(!_uiElementInput){
        _uiElementInput = [[GPUImageUIElement alloc] initWithView:self.watermarkView];
    }
    return _uiElementInput;
}


- (GPUImageAlphaBlendFilter *)blendFilter{
    if(!_blendFilter){
        _blendFilter = [[GPUImageAlphaBlendFilter alloc] init];
        _blendFilter.mix = 1.0;
        [_blendFilter disableSecondFrameCheck];
    }
    return _blendFilter;
}

- (void)setWatermarkView:(UIView *)watermarkView Block:(WatermarkBlock)block;
{
    if(_watermarkView){
    
    }
    _watermarkBlock = block;
    self.watermarkView = watermarkView;
    
}




- (void)videoWaterMark:(BOOL)bwaterMark
{
    [self cleanFilters];
    if (self.watermarkView && bwaterMark) {
        
        GPUImageOutput<UCloudGPUImageInput> *lastFilter = (GPUImageOutput<UCloudGPUImageInput> *)_videoCamera;

        [lastFilter addTarget:self.blendFilter];
        [self.uiElementInput addTarget:self.blendFilter];
        [self.blendFilter addTarget:self.emptyFilter];
        
        __weak UCloudGPUImageUIElement *weakUielement = _uiElementInput;
        [lastFilter setFrameProcessingCompletionBlock:^(GPUImageOutput *outPut, CMTime time) {
            if (_watermarkBlock) {
                _watermarkBlock();
            }
            [weakUielement update];
        }];
        
    }
    else
    {
    
        [_videoCamera addTarget:self.emptyFilter];
        [self.emptyFilter addTarget:self.previewView];
    }

}

-(void) cleanFilters
{
    if (_videoCamera) {
        [_videoCamera removeAllTargets];
    }
    
    if (_blendFilter) {
         [_blendFilter removeAllTargets];
    }
   
    if (_uiElementInput) {
        [_uiElementInput removeAllTargets];
    }
 
}


- (void)willOutputSampleBuffer:(CMSampleBufferRef)sampleBuffer
{
    
    CVPixelBufferRef pixelBuffer = CMSampleBufferGetImageBuffer(sampleBuffer);
    
    
    UIDeviceOrientation iDeviceOrientation = [[UIDevice currentDevice] orientation];
    BOOL mirrored;
    
    mirrored = !self.kwSdkUI.kwSdk.cameraPositionBack && self.videoCamera.horizontallyMirrorFrontFacingCamera;
    
    cv_rotate_type cvMobileRotate;
    
    switch (iDeviceOrientation) {
        case UIDeviceOrientationPortrait:
        case UIDeviceOrientationFaceUp:
        case UIDeviceOrientationFaceDown:
            cvMobileRotate = CV_CLOCKWISE_ROTATE_90;
            [Global sharedManager].PIXCELBUFFER_ROTATE = KW_PIXELBUFFER_ROTATE_0;
            break;
            
        case UIDeviceOrientationLandscapeLeft:
            cvMobileRotate = mirrored ? CV_CLOCKWISE_ROTATE_180 : CV_CLOCKWISE_ROTATE_0;
            [Global sharedManager].PIXCELBUFFER_ROTATE = KW_PIXELBUFFER_ROTATE_270;
            break;
            
        case UIDeviceOrientationLandscapeRight:
            cvMobileRotate = mirrored ? CV_CLOCKWISE_ROTATE_0 : CV_CLOCKWISE_ROTATE_180;
            [Global sharedManager].PIXCELBUFFER_ROTATE = KW_PIXELBUFFER_ROTATE_90;
            break;
            
        case UIDeviceOrientationPortraitUpsideDown:
            cvMobileRotate = CV_CLOCKWISE_ROTATE_270;
            [Global sharedManager].PIXCELBUFFER_ROTATE = KW_PIXELBUFFER_ROTATE_180;
            break;
            
        default:
            cvMobileRotate = CV_CLOCKWISE_ROTATE_0;
            break;
    }
    
    [self.kwSdkUI.kwSdk.renderer processPixelBuffer:pixelBuffer withRotation:cvMobileRotate mirrored:mirrored];
    
    if (!self.kwSdkUI.kwSdk.renderer.trackResultState) {
        NSLog(@"没有捕捉到人脸！！！！！！！！！！！！！！！！！！！！！！！！！");
    }
    else
    {
//        NSLog(@"捕捉到人脸！！！！！！！！！！！！！！！！！！！！！！！！！");
    }
    
    /*********** 如果有拍照功能则必须加上 ***********/
    self.outputImage =  [CIImage imageWithCVPixelBuffer:pixelBuffer];
    self.outputWidth = CVPixelBufferGetWidth(pixelBuffer);
    self.outputheight = CVPixelBufferGetHeight(pixelBuffer);
    /*********** End ***********/


}
- (void)outputPixelBuffer {
    __weak typeof(self) weakself = self;
    [self.emptyFilter setFrameProcessingCompletionBlock:^(GPUImageOutput *outPut, CMTime time) {
        GPUImageFramebuffer *imageFramebuffer = outPut.framebufferForOutput;
        __block CVPixelBufferRef pixelBuffer = [imageFramebuffer pixelBuffer];
        
        [weakself.ucdLiveEngine pushPixelBuffer:pixelBuffer completion:nil];
    }];
}


-(void)didClickOffPhoneButton
{
    [self takePhoto];
}

//拍照
- (void)takePhoto
{
    if (self.outputImage) {
        
        /* 录制demo 前置摄像头修正图片朝向*/
        UIImage *processedImage = [self image:[self convertBufferToImage] rotation:UIImageOrientationRight];
        UIImageWriteToSavedPhotosAlbum(processedImage, self, @selector(image:finishedSavingWithError:contextInfo:), nil);
    }
}

- (UIImage *)convertBufferToImage
{
    CIContext *temporaryContext = [CIContext contextWithOptions:nil];
    CGImageRef videoImage = [temporaryContext
                             createCGImage:self.outputImage
                             fromRect:CGRectMake(0, 0,
                                                 self.outputWidth,
                                                 self.outputheight)];
    
    UIImage *uiImage = [UIImage imageWithCGImage:videoImage];
    CGImageRelease(videoImage);
    return uiImage;
}


- (void)image:(UIImage *)image finishedSavingWithError:(NSError *)error contextInfo: (void *) contextInfo
{
    UIAlertController *alertView = [[UIAlertController alloc]init];
    UIAlertAction *cancelAction = [UIAlertAction actionWithTitle:@"好的" style:UIAlertActionStyleCancel handler:nil];
    [alertView addAction:cancelAction];
    [alertView setTitle:@"提示"];
    
    if (error) {
        [alertView setMessage:[NSString stringWithFormat:@"拍照失败，原因：%@",error]];
        
        NSLog(@"save failed.");
    } else {
        [alertView setMessage:[NSString stringWithFormat:@"拍照成功！相片已保存到相册！"]];
        NSLog(@"save success.");
    }
    [self presentViewController:alertView animated:NO completion:nil];
}

- (UIImage *)image:(UIImage *)image rotation:(UIImageOrientation)orientation
{
    long double rotate = 0.0;
    CGRect rect;
    float translateX = 0;
    float translateY = 0;
    float scaleX = 1.0;
    float scaleY = 1.0;
    
    switch (orientation) {
        case UIImageOrientationLeft:
            rotate = M_PI_2;
            rect = CGRectMake(0, 0, image.size.height, image.size.width);
            translateX = 0;
            translateY = -rect.size.width;
            scaleY = rect.size.width/rect.size.height;
            scaleX = rect.size.height/rect.size.width;
            break;
        case UIImageOrientationRight:
            rotate = 3 * M_PI_2;
            rect = CGRectMake(0, 0, image.size.height, image.size.width);
            translateX = -rect.size.height;
            translateY = 0;
            scaleY = rect.size.width/rect.size.height;
            scaleX = rect.size.height/rect.size.width;
            break;
        case UIImageOrientationDown:
            rotate = M_PI;
            rect = CGRectMake(0, 0, image.size.width, image.size.height);
            translateX = -rect.size.width;
            translateY = -rect.size.height;
            break;
        default:
            rotate = 0.0;
            rect = CGRectMake(0, 0, image.size.width, image.size.height);
            translateX = 0;
            translateY = 0;
            break;
    }
    
    UIGraphicsBeginImageContext(rect.size);
    CGContextRef context = UIGraphicsGetCurrentContext();
    //做CTM变换
    CGContextTranslateCTM(context, 0.0, rect.size.height);
    CGContextScaleCTM(context, 1.0, -1.0);
    CGContextRotateCTM(context, rotate);
    CGContextTranslateCTM(context, translateX, translateY);
    
    CGContextScaleCTM(context, scaleX, scaleY);
    //绘制图片
    CGContextDrawImage(context, CGRectMake(0, 0, rect.size.width, rect.size.height), image.CGImage);
    
    UIImage *newPic = UIGraphicsGetImageFromCurrentImageContext();
    
    if (!self.kwSdkUI.kwSdk.cameraPositionBack) {
        newPic = [self convertMirrorImage:newPic];
    }
    
    
    return newPic;
}

- (UIImage *)convertMirrorImage:(UIImage *)image
{
    
    //Quartz重绘图片
    CGRect rect =  CGRectMake(0, 0, image.size.width , image.size.height);//创建矩形框
    //根据size大小创建一个基于位图的图形上下文
    UIGraphicsBeginImageContextWithOptions(rect.size, false, 2);
    CGContextRef currentContext =  UIGraphicsGetCurrentContext();//获取当前quartz 2d绘图环境
    CGContextClipToRect(currentContext, rect);//设置当前绘图环境到矩形框
    CGContextRotateCTM(currentContext, (CGFloat)M_PI); //旋转180度
    //平移， 这里是平移坐标系，跟平移图形是一个道理
    CGContextTranslateCTM(currentContext, -rect.size.width, -rect.size.height);
    CGContextDrawImage(currentContext, rect, image.CGImage);//绘图
    
    //翻转图片
    UIImage *drawImage =  UIGraphicsGetImageFromCurrentImageContext();//获得图片
    UIImage *flipImage =  [[UIImage alloc]initWithCGImage:drawImage.CGImage];
    
    
    return flipImage;
}




//更新约束
- (void)updateViewConstraints {
    [super updateViewConstraints];
    //设置为两个屏幕的宽度
    self.viewWidth.constant = CGRectGetWidth([UIScreen mainScreen].bounds) * 2;
    self.secondViewLeading.constant = CGRectGetWidth([UIScreen mainScreen].bounds);
    self.btnStopWidth.constant = CGRectGetWidth([UIScreen mainScreen].bounds) / 4;
}

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    
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
    
    //5以下支持4：3, 5以上的支持16：9
    if ([_ucdLiveEngine lowThan5]) {
        _ucdLiveEngine.width = 640;
        _ucdLiveEngine.height = 480;
    } else {
        _ucdLiveEngine.width = 640;
        _ucdLiveEngine.height = 360;
    }
    //横屏推流
    if (_ucdLiveEngine.videoOrientation == UCloudVideoOrientationLandscapeRight) {
        //宽高比例相互替换
        CGFloat width = _ucdLiveEngine.width;
        CGFloat height = _ucdLiveEngine.height;
        _ucdLiveEngine.height  = width;
        _ucdLiveEngine.width = height;
    }
    _ucdLiveEngine.fps = 20;
    _ucdLiveEngine.supportFilter = YES;
    
    self.filterManager = [[FilterManager alloc] init];
    liveFilters = [self.filterManager filters];
    
    //如果需要设置显示图像的frame，iOS8以下请在此先设置，直接使用getCameraView方法获取view进行设置是无作用的，iOS8以上两者都可设置frame
//    [_ucdLiveEngine initializeCameraViewFrame:CGRectMake(10, 10, 240, 230)];
    _ucdLiveEngine.secretKey = AccessKey;
    _ucdLiveEngine.bitrate = UCloudVideoBitrateMedium;
    
    [self adddWaterMark];
    __weak PublishViewController *weakSelf = self;
    [_ucdLiveEngine configureCameraWithOutputUrl:_publishUrl filter:nil messageCallBack:^(UCloudCameraCode code, NSInteger arg1, NSInteger arg2, id data) {
        
        [weakSelf handlerMessageCallBackWithCode:code arg1:arg1 arg2:arg2 data:data weakSelf:weakSelf];
    } deviceBlock:^(AVCaptureDevice *dev) {
        
        [self handlerDeviceBlock:dev weakSelf:weakSelf];
    } cameraData:^CVPixelBufferRef(CVPixelBufferRef buffer) {
        //如果不需要裸流，不建议在这里执行操作，将增加额外的功耗
        return nil;
    }];
}

- (void)handlerMessageCallBackWithCode:(UCloudCameraCode)code arg1:(NSInteger)arg1 arg2:(NSInteger)arg2 data:(id)data weakSelf:(PublishViewController *)weakSelf
{
    [[NSNotificationCenter defaultCenter] postNotificationName:@"UCloudCameraStateUpdateNotification" object:@{@"state": @(code)}];
    NSString *codeStr = [NSString stringWithFormat:@"%ld",(unsigned long)code];
    NSLog(@"state:%@", [codeStr cameraCodeToMessage]);
    
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


#pragma mark - watermark view

- (void)adddWaterMark
{
    CGSize size;
    CGSize sizeOrigin = [UIScreen mainScreen].bounds.size;
    size = sizeOrigin;
    if (self.direction == UCloudVideoOrientationLandscapeRight ||
        self.direction == UCloudVideoOrientationLandscapeLeft) {
        if (sizeOrigin.width < sizeOrigin.height) {
            size = CGSizeMake(sizeOrigin.height, sizeOrigin.width);
        }
    } else {
        if (sizeOrigin.width > sizeOrigin.height) {
            size = CGSizeMake(sizeOrigin.height, sizeOrigin.width);
        }
    }
    
    UILabel *label = [[UILabel alloc] initWithFrame:CGRectMake(55, 20, size.width, 30)];
    label.textAlignment = NSTextAlignmentLeft;
    label.text = @"我是水印";
    UIImageView *imgV = [[UIImageView alloc]initWithFrame:CGRectMake(68, 50, 30, 30)];
    imgV.image = [UIImage imageNamed:@"ucloud_logo"];
    imgV.alpha = 0.75;
    UIView *subView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, size.width, size.height)];
    subView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    subView.backgroundColor = [UIColor clearColor];
    [subView addSubview:label];
    [subView addSubview:imgV];
    self.waterMarkView = subView;
    NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
    [dateFormatter setDateFormat:@"yyyy-MM-dd HH:mm:ss:SSS"];
    self.waterMarkView = subView;
    [self setWatermarkView:subView Block:^{
        label.text = [NSString stringWithFormat:@"%@", [dateFormatter stringFromDate: [NSDate date]]];
    }];
}

- (void)removeWaterMark
{
    if (self.waterMarkView) {
        for (UIView* subView in self.waterMarkView.subviews) {
            [subView removeFromSuperview];
        }
        [self.waterMarkView removeFromSuperview];
        self.waterMarkView = nil;
    }
    
}


#pragma mark - UIButton Event

- (IBAction)btnStopTouchUpInside:(id)sender
{
    
   
    //取消监听
    [self cancelMonitorPublishState];
    [UIApplication sharedApplication].idleTimerDisabled = NO;
    
    
    __weak PublishViewController *weakSelf = self;
    
    [_ucdLiveEngine shutdown:^{
        if (weakSelf.videoView) {
            [weakSelf.videoView removeFromSuperview];
        }
        weakSelf.videoView = nil;
        [weakSelf removeWaterMark];
        
        
    }];
    
    [self dismissViewControllerAnimated:YES completion:^{

        [weakSelf.kwSdkUI popAllView];
        /* 内存释放 */
        [KWSDK_UI releaseManager];
        [KWSDK releaseManager];
        weakSelf.kwSdkUI.kwSdk = nil;
        weakSelf.kwSdkUI = nil;

    
    }];
}

- (IBAction)btnStartLiveTouchUpInside:(id)sender {
    
    UIButton *btn = (UIButton *)sender;
    btn.selected = YES;
    
    [_ucdLiveEngine cameraStart];
    
    //监听发送状态
    [self monitorPublishState];
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
    
    if (self.videoCamera.cameraPosition == AVCaptureDevicePositionBack) {
        return;
    }
    
    UIButton *btnMirror = (UIButton *)sender;
    if (btnMirror.selected) {
        btnMirror.selected = NO;
    }
    else {
        btnMirror.selected = YES;
    }
    self.videoCamera.horizontallyMirrorFrontFacingCamera = !self.videoCamera.horizontallyMirrorFrontFacingCamera;
    if (btnMirror.selected) {
        
        [self.previewView setInputRotation:kGPUImageNoRotation atIndex:0];
    }
    else {
        
        [self.previewView setInputRotation:kGPUImageFlipHorizonal atIndex:0];
    }

}

- (IBAction)btnChangeCaptureTouchUpInside:(id)sender {
    
    [_ucdLiveEngine changeCamera];
    
    if([_ucdLiveEngine currentCapturePosition] == AVCaptureDevicePositionBack){
        self.btnTorch.enabled = YES;
        if (!self.videoCamera.horizontallyMirrorFrontFacingCamera) {
            [self.previewView setInputRotation:kGPUImageNoRotation atIndex:0];
        }
        
    } else {
        self.btnTorch.enabled = NO;
        if (self.btnTorch.selected) {
            self.btnTorch.selected = NO;
        }
       
    }
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
    
    UIButton *btnFilter = (UIButton *)sender;
    if (btnFilter.selected) {
        btnFilter.selected = NO;
        [self videoWaterMark:NO];
        
    }
    else {
        btnFilter.selected = YES;
        [self videoWaterMark:YES];
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
    
    PopoverView *popoverView = [PopoverView popoverView];
    popoverView.style = PopoverViewStyleDark;
    // 在没有系统控件的情况下调用可以使用显示在指定的点坐标的方法弹出菜单控件.
    
    CGRect frame = _buttomView.frame;
    [popoverView showToPoint:CGPointMake(frame.size.height / 8, frame.origin.y) withActions:@[actionSmooth, action2, action3]];
}

- (IBAction)btnFaceUTouchUpInside:(id)sender {
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

#pragma mark - 私有方法


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
    if (avg > _bitrate)
    {
        avg = _bitrate;
    }
    float decibels = avg / _bitrate * range;
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
    if (System_Version < 9.0) {
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
    if (!_isPortrait) {
        return YES;
    }
    
    return NO;
}

- (UIInterfaceOrientationMask)supportedInterfaceOrientations
{
    //viewController所支持的全部旋转方向
    if (!_isPortrait) {
        return UIInterfaceOrientationMaskLandscapeRight;
    }
    
    return UIInterfaceOrientationMaskPortrait | UIInterfaceOrientationMaskLandscapeLeft | UIInterfaceOrientationMaskLandscapeRight;
}

- (UIInterfaceOrientation)preferredInterfaceOrientationForPresentation
{
    //viewController初始显示的方向
    if (!_isPortrait) {
        return UIInterfaceOrientationLandscapeRight;
    }
    
    return UIInterfaceOrientationPortrait;
}


@end
