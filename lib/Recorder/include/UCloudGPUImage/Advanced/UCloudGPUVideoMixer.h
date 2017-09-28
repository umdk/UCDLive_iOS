//
//  UCloudGPUVideoMixer.h
//  GPUImage
//
//  Created by Sidney on 17/05/17.
//  Copyright © 2017年 Brad Larson. All rights reserved.
//

#import "UCloudGPUImage.h"
#import <AVFoundation/AVFoundation.h>

extern NSString *const kGPUImageVideoMixerFragmentShaderString;

/*!
 *  图层混合filter，可将多个图层混合显示
 */
@interface UCloudGPUVideoMixer:UCloudGPUImageFilter

/**
 @abstract   设置主要图层 (默认为0)
 @discussion 主要图层一般为视频图层, 当主要图层的输入刷新时, 输出才刷新
 */
@property (nonatomic, assign) NSUInteger masterLayer;

/**
 @abstract   初始化
 @discussion 输出大小等于主要图层的大小
 */
- (id)init;

/*!
 *  设置图层的位置和大小(0.0-1.0)，以当前视图的比例来计算
 *
 *  @param rect         大小和位置
 *  @param textureIndex 图层的索引
 */
- (void)setVideoRect:(CGRect)rect ofLayer:(NSInteger)textureIndex;

/*!
 *  获取图层的位置和大小
 *
 *  @param textureIndex textureIndex 图层的索引
 *
 *  @return 位置和大小
 */
- (CGRect)getVideoRectOfLayer:(NSInteger)textureIndex;

/*!
 *  设置图层的透明度(默认为1.0)
 *
 *  @param alpha        透明度(0~1.0), 0为全透明
 *  @param textureIndex 图层索引
 */
- (void)setVideoAlpha:(CGFloat)alpha ofLayer:(NSInteger)textureIndex;

/*!
 *  获取图层的透明度
 *
 *  @param textureIndex 图层的索引
 *
 *  @return 透明度
 */
- (CGFloat)getVideoAlphaOfLayer:(NSInteger)textureIndex;

/*!
 *  设置图层的方向 (默认为kUCloudGPUImageNoRotation)，镜像：kUCloudGPUImageFlipHorizonal
 *
 *  @param rotation     相关图层方向
 *  @param textureIndex 图层索引
 */
- (void)setVideoRotation:(UCloudGPUImageRotationMode)rotation ofLayer:(NSInteger)textureIndex;

/*!
 *  获取图层的旋转模式
 *
 *  @param textureIndex 图层索引
 *
 *  @return 旋转方式
 */
- (UCloudGPUImageRotationMode)getVideoRotationOfLayer:(NSInteger)textureIndex;

/*!
 *  清除相关图层的内容
 *
 *  @param textureIndex 图层索引
 */
- (void)clearVideoOfLayer:(NSInteger)textureIndex;

@end
