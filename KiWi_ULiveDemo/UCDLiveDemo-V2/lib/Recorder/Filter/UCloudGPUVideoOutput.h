//
//  UCloudGPUVideoOutput.h
//  GPUImage
//
//  Created by Sidney on 31/05/17.
//  Copyright © 2017年 Brad Larson. All rights reserved.
//

#import "UCloudGPUImage.h"
#import <Foundation/Foundation.h>

@interface UCloudGPUVideoOutput : NSObject<UCloudGPUImageInput>

/**
 @abstract 输出格式：kCVPixelFormatType_32BGRA
 */
@property(nonatomic, readonly) OSType outputPixelFormat;

/**
 @abstract   UCloudGPUImageInput - (BOOL)enabled;
 */
@property(nonatomic, assign) BOOL enabled;

/**
 @property bCustomOutputSize
 @abstract 是否使用自定义输出尺寸 (默认为NO)
 */
@property(nonatomic, assign) BOOL bCustomOutputSize;

/**
 @property outputSize
 @abstract output picture size
 @discussion 当bCustomOutputSize设置为NO时,outputSize无法被修改
 @see bCustomOutputSize
 */
@property(nonatomic, assign) CGSize outputSize;

/**
 @property inputSize
 @abstract input picture size
 */
@property(nonatomic, readonly) CGSize inputSize;

/**
 @abstract 初始化方法
 */
- (id) init;

/**
 @abstract input roation mode
 */
- (UCloudGPUImageRotationMode) getInputRotation;

/*!
 @abstract   视频处理回调接口
 @discussion pixelBuffer 美颜后编码前的视频数据
 @discussion timeInfo    时间戳
 */
@property(nonatomic, copy) void(^videoProcessingCallback)(CVPixelBufferRef pixelBuffer, CMTime timeInfo );

@end

