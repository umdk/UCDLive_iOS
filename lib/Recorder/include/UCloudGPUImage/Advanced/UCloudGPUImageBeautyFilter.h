//#if __has_include(<GPUImage/GPUImageFramework.h>)
//#import <GPUImage/GPUImageFramework.h>
//#else
//#import "GPUImage.h"
//#endif

#import <Foundation/Foundation.h>
#import "UCloudGPUImageFilter.h"

@interface UCloudGPUImageBeautyFilter : UCloudGPUImageFilter {
}

@property (nonatomic, assign) CGFloat smoothLevel;
@property (nonatomic, assign) CGFloat brightLevel;
@property (nonatomic, assign) CGFloat toneLevel;
@end
