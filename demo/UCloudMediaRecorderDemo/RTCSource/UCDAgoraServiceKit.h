//
//  UCDAgoraServiceKit.h
//  UCloudMediaRecorderDemo
//
//  Created by Sidney on 6/13/17.
//  Copyright © 2017 https://UCloud.cn. All rights reserved.

#import <Foundation/Foundation.h>
#import <AVFoundation/AVFoundation.h>

@class UCDAgoraClient;

@interface UCDAgoraServiceKit: NSObject

#pragma mark - 声网sdk相关
/**
 @abstract rtc接口类
 */
@property (nonatomic, strong) UCDAgoraClient *agoraKit;

/*!
 *  判断是否已经退出连麦
 */
@property (nonatomic, assign) BOOL bExitFlag;

/*
 @abstract start call的回调函数
 */
@property (nonatomic, copy)void (^onCallStart)(int status);

/*
 @abstract stop call的回调函数
 */
@property (nonatomic, copy)void (^onCallStop)(int status);

/*
 @abstract 加入channel回调
 */
@property (nonatomic, copy)void (^onChannelJoin)(int status);


/*!
 *  是否镜像
 */
@property (nonatomic, assign) BOOL bMirror;

/*!
 *  是否正在切换滤镜
 */
@property (nonatomic, assign) BOOL bFiltering;


/*
 @abstract 呼叫开始
 */
@property (nonatomic, readwrite) BOOL callstarted;

#pragma mark - 窗口相关配置
/*
 @abstract 摄像头图层
 */
@property (nonatomic, readwrite) NSInteger cameraLayer;

/*
 @abstract 小窗口图层
 */
@property (nonatomic, readwrite) NSInteger rtcLayer;

/**
 @abstract 小窗口图层的大小
 */
@property (nonatomic, readwrite) CGRect winRect;

/*
 @abstract 自定义图层母类，可往里addview
 */
@property (nonatomic, readwrite) UIView *contentView;

/**
 @abstract 主窗口和小窗口切换
 */
@property (nonatomic, readwrite) BOOL selfInFront;

/**
 @abstract 圆角的图片
 */
@property UCloudGPUImagePicture *maskPicture;

#pragma 美颜相关
/*
 @abstract 美颜滤镜
 */
@property UCloudGPUImageOutput<UCloudGPUImageInput> *curfilter;

/**
 @abstract 初始化方法
 @discussion 创建带有默认参数的 kit
 @warning kit只支持单实例推流，构造多个实例会出现异常
 */
- (instancetype)initWithDefaultConfig;

/*
 @abstract 加入通道
 */
-(void)joinChannel:(NSString *)channelName;

/*
 @abstract 离开通道
 */
-(void)leaveChannel;

/**
 @abstract 加入rtc窗口滤镜
 */
- (void) setupRtcFilter:(UCloudGPUImageOutput<UCloudGPUImageInput> *)filter;

@end

