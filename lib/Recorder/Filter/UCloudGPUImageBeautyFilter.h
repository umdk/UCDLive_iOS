//
//  GPUImageBeautyFilter.h
//  GPUImage
//
//  Created by yisanmao on 16/2/1.
//  Copyright © 2016年 Brad Larson. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "UCloudGPUImageFilter.h"

@interface UCloudGPUImageBeautyFilter : UCloudGPUImageFilter {
}

@property (nonatomic, assign) CGFloat smoothLevel;
@property (nonatomic, assign) CGFloat brightLevel;
@property (nonatomic, assign) CGFloat toneLevel;
@end
