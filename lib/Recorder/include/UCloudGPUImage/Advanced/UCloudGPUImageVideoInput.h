//
//  UCloudGPUImageVideoInput.h
//  GPUImage
//
//  Created by Sidney on 16/05/17.
//  Copyright © 2017年 Brad Larson. All rights reserved.
//

#import "UCloudGPUImage.h"
#import <CoreMedia/CoreMedia.h>
#import <AVFoundation/AVFoundation.h>

//Optionally override the YUV to RGB matrices
//void setYUVColorConversion601( GLfloat conversionMatrix[9] );
//void setYUVColorConversion601FullRange( GLfloat conversionMatrix[9] );
//void setYUVColorConversion709( GLfloat conversionMatrix[9] );

/*!
 *  接收YUV数据，并上传到GPU
 */
@interface UCloudGPUImageVideoInput : UCloudGPUImageOutput {
    dispatch_semaphore_t frameRenderingSemaphore;
    GLuint luminanceTexture, chrominanceTexture;
}

@property(nonatomic, assign)AVCaptureDevicePosition      devCurrentPos;
@property(nonatomic, assign)UCloudGPUImageRotationMode outputRotation;
@property(nonatomic, assign)UCloudGPUImageRotationMode internalRotation;
@property(nonatomic, assign)UIInterfaceOrientation      outputImageOrientation;
@property(nonatomic, assign)BOOL          horizontallyMirrorFrontFacingCamera;

/*!
 *  Initialization
 */
- (id)init;



/** sitting video Formate
 
 @param isCaptureAsYUV YES:YUV NO RGBA
 @param iSFullYUVRange if YUV YES:NV12 NO I420 if isCaptureAsYUV is NO iSFullYUVRange is no need
 */
- (id)initWithYUVVideo:(BOOL)isCaptureAsYUV  iSFullYUVRange:(BOOL)bFullYUVRange;

/**
 @abstract 输入图像数据
 @param    sampleBuffer 图像数据和时间戳
 */
- (void)processSampleBuffer:(CMSampleBufferRef)sampleBuffer;

/**
 @abstract 输入图像数据
 @param    pixelBuffer 图像数据
 @param    timeInfo    时间戳
 */
- (void)processPixelBuffer:(CVPixelBufferRef)pixelBuffer
                      time:(CMTime)timeInfo;
@end
