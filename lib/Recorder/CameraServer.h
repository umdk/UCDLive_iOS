//
//  CameraServer.h
//
//  Created by sidney on 19/10/2015.
//  Copyright © 2015年 https://ucloud.cn/. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <AVFoundation/AVFoundation.h>
#import "UCloudGPUImage.h"
#import "UCloudRecorderTypeDef.h"

/*!
 @abstract 推流状态回调
 * NSInteger arg1, 预留未定义
 * NSInteger arg2, 预留未定义
 */
typedef void(^CameraMessage)(UCloudCameraCode code, NSInteger arg1, NSInteger arg2, id data);
/// 相机回调
typedef void(^CameraDevice)(AVCaptureDevice *dev);

//typedef CMSampleBufferRef (^CameraData)(CMSampleBufferRef buffer);
typedef CVPixelBufferRef (^CameraData)(CVPixelBufferRef buffer);

typedef void(^videoProcessingCallback)(CVPixelBufferRef pixelBuffer, CMTime timeInfo );

typedef void(^WatermarkBlock)(void);

/*!
 CameraServer
 
 UCloud直播推流SDK iOS版提供了iOS移动设备上的实时采集推流功能。
 */
@interface CameraServer : NSObject

/*!
 @property width
 @abstract 视频宽，默认360
 */
@property (assign, nonatomic) int width;

/*!
 @property height
 @abstract 视频高，默认640
 */
@property (assign, nonatomic) int height;

@property (strong, nonatomic) UCloudGPUImageVideoCamera *videoCamera;

/*!
 @property fps
 @abstract 帧率(15\20\25\30)，默认15
 
 @discussion video frame per seconds 有效范围[1~30], 超出会提示参数错误
 */
@property (assign, nonatomic) int fps;

/*!
 @property bitrate
 @abstract 音频和视频总比特率UCloudVideoBitrate
 
 @discussion 默认UCloudVideoBitrateMedium，可自行设置，该属性的单位为kbps(kilo bits per seccond)
 @discussion 视频码率高则画面较清晰，低则画面较模糊，同时数据亦是如此，码率高数据大，码率低数据小
 */
@property (assign, nonatomic) int bitrate;


/*!
 @property audiochannels
 @abstract  音频采集通道数 默认是1
 */
@property (assign, nonatomic) int audiochannels;

/*!
 @property audioSamplerate
 @abstract 音频采样率(48000,44100 32000,22050,22050,11025默认44100）
 */
@property (assign, nonatomic) int audioSamplerate;


/*!
 @property audioBitrate
 @abstract 音频比特率(32kps,64kps,96kps,128kps默认128kps,采样率小于441100时，比特率应不大于64kps)
*/
@property (assign, nonatomic) int audioBitrate;
 
/*!
 @property secretKey
 @abstract SDK 鉴权密钥
 
 @discussion Ulive鉴权，如果填写错误会返回错误码UCloudCamera_AuthFail
 */
@property (strong, nonatomic) NSString *secretKey;

/*!
 *property audioPlayStr
 @abstract 背景音乐路径
 */

@property (nonatomic,   copy) NSString *audioPlayStr;

/*!
 @property supportFilter
 @abstract 是否支持滤镜
 
 @discussion iphpne5以上才能支持使用滤镜，5以下此值为NO
 */
@property (assign, nonatomic) BOOL supportFilter;

/*!
 @property captureDevicePos
 @abstract 摄像头位置，默认打开前置摄像头
 */
@property (assign, nonatomic) AVCaptureDevicePosition captureDevicePos;

/*!
 @property muted
 @abstract 是否静音，默认NO
 */
@property (nonatomic, assign) BOOL muted;

/*!
 @property backgroudMusicOn
 @abstract 是否开启背景音乐，默认NO
 */
@property (nonatomic, assign) BOOL backgroudMusicOn;

/*!
 @property videoOrientation
 @abstract 视频推流方向
 
 @discussion 只在采集初始化时设置有效，默认UIDeviceOrientationPortrait
 */
@property (nonatomic, assign) UCloudVideoOrientation videoOrientation;

/*!
 @property streamMirrorFrontFacing
 @abstract 推流镜像，只对前置有效
 */
@property (nonatomic, assign) BOOL streamMirrorFrontFacing;

/*!
 @property reconnectInterval
 @abstract 重推流间隔,默认3秒
 */
@property (nonatomic, assign) NSTimeInterval reconnectInterval;

/*!
 @property reconnectCount
 @abstract 重推流次数，默认5次
 
 @discussion 如果需要不做重推操作，可将此参数设置为0
 */
@property (nonatomic, assign) NSInteger reconnectCount;

/*!
 @property isCaptureYUV
 @abstract 摄像头采集数据为YUV还是RGB
 
 @discussion 默认为YES，即采集数据为YUV，NO为采集数据为RGB
 */
@property (assign, nonatomic) BOOL isCaptureYUV;

/**
 @property enableLogFile
 @abstract 是否开启日志文件，默认开启
 */
@property (assign, nonatomic) bool enableLogFile;

/**
 @property logLevel
 @abstract 日志输出等级设置，默认UCDLiveLogLevelInfo
 */
@property (assign, nonatomic) UCDLiveLogLevel logLevel;

/**
 @property logFiles
 @abstract 所有日志文件名
 */
@property (strong, nonatomic, readonly) NSArray *logFiles;

/**
 @property logsDirectory
 @abstract 日志文件路径，默认Documents/Logs/UCloud/ULive
 */
@property (strong, nonatomic) NSString *logsDirectory;

/**
 @property lastLogFilePath
 @abstract 最近的日志文件路径
 */
@property (strong, nonatomic, readonly) NSString *lastLogFilePath;

/**
 @property lastLogFileName
 @abstract 最近的日志文件名
 */
@property (strong, nonatomic, readonly) NSString *lastLogFileName;

/**
 @property logFileSize
 @abstract 每个日志文件的大小，每个日志文件如若达到该大小将会进行一次压缩保存，减少沙盒使用量，默认1M
 */
@property (assign, nonatomic) NSInteger logFileSize;

/**
 @property logFilesMaxSize
 @abstract 日志文件夹大小，超过会清理日志，默认20M
 */
@property (assign, nonatomic) NSInteger logFilesMaxSize;

@property (copy, nonatomic) videoProcessingCallback videoProcessing;

/**
 *  @property streamPushUrlstr;
 *  @abstract 音视频推流地址
 */
@property (strong, nonatomic) NSString* streamPushUrlstr;


/*!
 @method server
 @abstract CameraServer单例模式
 
 @discussion CameraServer只支持单例推流，若构造多个实例会造成不同估量的异常
 
 * width             = 360;
 * height            = 640;
 * fps               = 15;
 * muted             = NO;
 * reconnectCount    = 5;
 * reconnectInterval = 3;
 * bitrate           = UCloudVideoBitrateMedium;
 * videoOrientation  = UCloudVideoOrientationPortrait
 * captureDevicePos  = AVCaptureDevicePositionFront;
 */
+ (CameraServer*) server;

/*!
 @method setWatermarkView:Block:
 
 @abstract 设置水印
 
 @param watermarkView 设置水印视图
 */
- (void)setWatermarkView:(UIView *)watermarkView Block:(WatermarkBlock)block;

/*!
 @method configureCameraWithOutputUrl:filter:messageCallBack:deviceBlock:cameraData:
 @abstract server初始化(不会自动开始要在底层配置完成之后调用cameraStart)
 
 @param outPutUrl   推流地址
 @param filters     滤镜组
 @param block       推流状态回调
 @param deviceBlock 相机回调(定制相机参数)
 @param cameraData  视频数据
 
 @discussion 推流从此进入
 */
- (void)configureCameraWithOutputUrl:(NSString *)outPutUrl filter:(NSArray *)filters messageCallBack:(CameraMessage)block deviceBlock:(CameraDevice)deviceBlock cameraData:(CameraData)cameraData;

/*!
 @method cameraPrepare
 @abstract 打开摄像头预览，不进行推流上传
 */
- (void)cameraPrepare;

/*!
 @method cameraStart
 @abstract 开始录像采集推流上传
 
 @return 返回操作结果
 */
- (BOOL)cameraStart;

/*!
 @method cameraStopPublish
 @abstract 停止推流上传
 */
- (void)cameraStopPublish;

/*!
 @method cameraResumePublish
 @abstract 恢复推流上传
 */
- (void)cameraResumePublish;

/*!
 @method cameraRestart
 @abstract 推流失败之后重新推流
 */
- (void)cameraRestart;

/*!
 @method shutdown
 @abstract 关闭视频采集并停止推流
 
 @param completion 关闭成功回调函数
 */
- (void)shutdown:(void(^)(void))completion;

/*!
 *method stopAudioModule
 @abstract 关闭模块内部声音采集
 */
- (void)stopAudioModule;

/*!
 *method startAudioModule
 @abstract 开启模块内部声音采集
 */
- (void)startAudioModule;


- (void)pushPixelBuffer:(CVPixelBufferRef)pixelBuffer completion:(void(^)(void))completion;

- (UCloudGPUImageView *)createBlurringScreenshot;

/*!
 @method getCameraView
 @abstract 获取采集图像
 
 @return 采集图像视图
 */
- (UIView*)getCameraView;

/*!
 @method initializeCameraViewFrame:
 @abstract 设置采集图像显示的frame
 
 @param frame 显示图像的大小
 @discussion 如果需要设置显示图像的frame，iOS8以下请在此先设置，直接使用getCameraView方法获取view进行设置是无作用的，iOS8以上两者都可设置frame
 */
- (void)initializeCameraViewFrame:(CGRect)frame;

/*!
 @method changeCamera
 @abstract 切换摄像头
 */
- (void)changeCamera;

/*!
 @method outBitrate
 @abstract 编码后的实际码率
 
 @return 码率值，包括视频码率和音频码率
 */
- (NSString *)outBitrate;

/*!
 @method setTorchState:
 @abstract 设置手电筒状态

 @param state 状态
 @return 设置是否成功
 */
- (BOOL)setTorchState:(UCloudCameraState)state;


/*!
 @method getStreamShot
 @abstract 对当前视频流数据截图，不同于手机截屏
 @return 截帧图像
 */
-(UIImage *)getStreamShot;

/*!
 @method currentCapturePosition
 @abstract 获取当前摄像头的位置
 
 @return 摄像头位置
 */
- (AVCaptureDevicePosition)currentCapturePosition;

/*!
 @method lowThan5
 @abstract 是否是iPhone5以下的机型
 
 @return 返回值
 */
- (BOOL)lowThan5;

/*!
 @method addFilters:
 @abstract 添加滤镜组
 
 @param filters 滤镜数组
 */
- (void)addFilters:(NSArray *)filters;

/*!
 @method openFilter
 @abstract 打开美颜功能
 */
- (void)openFilter;

/*!
 @method closeFilter
 @abstract 关闭美颜功能
 */
- (void)closeFilter;

/*！
 @ method    mixerAudioDataInBus:AudioData:
 @ abstract 多路音频数据合流
 @param busIndex  NSInteger 音频通道
 @param audiodata NSData*   该音频通道的音频数据
 */

-(void)mixerAudioDataInBus:(NSInteger)busIndex AudioData:(NSData*)audiodata;


/**
 * 获取SDK version
 */

-(NSString*)getSDKVersion;

@end
