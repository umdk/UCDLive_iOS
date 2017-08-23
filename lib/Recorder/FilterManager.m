//
//  UCloudFilterManager.m
//  UCloudMediaRecorderDemo
//
//  Created by yisanmao on 16/1/27.
//  Copyright © 2016年 https://ucloud.cn/. All rights reserved.
//

#import "FilterManager.h"
#import "CameraServer.h"
#import "UCloudGPUImage.h"
#import "UCloudGPUImagePhotoFilter.h"

#define SysVersion [[[UIDevice currentDevice] systemVersion] floatValue]

@interface FilterManager()

@property (strong, nonatomic) UCloudGPUImageBeautyFilter *beautyFilter;
@property (strong, nonatomic) UCloudGPUImagePhotoFilter *photoFilter;
//@property (nonatomic, strong) UCloudGPUImageBeautyFilter2 *beautyFilter2;
@end


@implementation FilterManager
- (NSArray *)filters
{
    if ([[CameraServer server] lowThan5]) {
        return nil;
    }
    else {
     
        if (!self.beautyFilter) {
            self.beautyFilter = [[UCloudGPUImageBeautyFilter alloc]init];
        }
//        return @[_beautyFilter];
        if (!self.photoFilter) {
            self.photoFilter = [[UCloudGPUImagePhotoFilter alloc]initWithImage:[UIImage imageNamed:@"2_sweety"]];
        }
        return @[_beautyFilter, _photoFilter];

        
//        //第二套滤镜方案
//        if (!self.beautyFilter2) {
//            self.beautyFilter2 = [[UCloudGPUImageBeautyFilter2 alloc]init];
//        }
//        return @[_beautyFilter2];
    }
}

- (void)setCurrentValue:(NSArray *)filterValues
{
    for (NSDictionary *filter in filterValues) {
        float current = [[filter objectForKey:@"current"] floatValue];
        NSString *type = [filter objectForKey:@"type"];
        [self valueChange:type value:current];
    }
}

- (void)valueChange:(NSString *)name value:(float)value
{
    if ([name isEqualToString:@"smooth"]) {
        [self.beautyFilter setSmoothLevel:value];
    }
    else if ([name isEqualToString:@"brightness"]) {
        [self.beautyFilter setBrightLevel:value];
    }
    else if ([name isEqualToString:@"tone"]) {
        [self.beautyFilter setToneLevel:value];
    }
    else if ([name isEqualToString:@"intensity"]) {
        [self.photoFilter setIntensity:value];
    }
}

- (NSMutableArray *)buildData
{
    NSArray *infos;
    if ([[CameraServer server] lowThan5]) {
        return nil;
    }
    else {
        if (SysVersion >= 8.f) {
            //第二套滤镜方案
            infos = @[
                      @{@"name":@"磨皮", @"type":@"smooth", @"min":@(0.0), @"max":@(100.0), @"current":@(60)},
                      @{@"name":@"亮度", @"type":@"brightness", @"min":@(0.0), @"max":@(100.0), @"current":@(50)},
                      @{@"name":@"色调", @"type":@"tone", @"min":@(0.0), @"max":@(100.0), @"current":@(50)},
                      @{@"name":@"场景", @"type":@"intensity", @"min":@(0.0), @"max":@(100.0), @"current":@(50)}
                      ];
        }
    }
    return [NSMutableArray arrayWithArray:infos];
}
@end
