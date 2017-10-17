//
//  UCloudGPUImagePhotoFilter.h
//  GPUImage
//
//  Created by Sidney on 2017/7/27.
//  Copyright © 2017年 Brad Larson. All rights reserved.
//

#import "UCloudGPUImage.h"

@interface UCloudGPUImagePhotoFilter : UCloudGPUImageFilterGroup

- (id)initWithImage:(UIImage *)image;

// 范围：0-100，默认50
@property(readwrite, nonatomic) CGFloat intensity;

@end
