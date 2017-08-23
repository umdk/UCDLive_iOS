//
//  InfoView.m
//  UCloudMediaRecorderDemo
//
//  Created by Sidney on 24/04/17.
//  Copyright © 2017年 https://ucloud.cn. All rights reserved.
//

#import "InfoView.h"
#import <mach/mach.h>
#import "sys/utsname.h"
#import "CameraServer.h"

@interface InfoView ()

@property (strong, nonatomic) NSTimer *timer;

@end


@implementation InfoView

- (instancetype)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        [self addSubview:self.lblBitrate];
        [self addSubview:self.lblFps];
        [self addSubview:self.lblState];
        [self addSubview:self.lblSys];
        [self addSubview:self.lblSDKVersion];
        [self addSubview:self.lblCpu];
        [self addSubview:self.lblPlatform];
        [self addSubview:self.lblUrl];
        
        self.timer = [NSTimer scheduledTimerWithTimeInterval:1.0f target:self selector:@selector(getBitrate) userInfo:nil repeats:YES];
        
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(updateState:) name:@"UCloudCameraStateUpdateNotification" object:nil];
    }
    return self;
}

- (void)showInfo:(NSDictionary *)info
{
    _lblCpu.text = [NSString stringWithFormat:@"CPU: %.2f%%", [info[@"cpu"] floatValue]];
    _lblSys.text = [NSString stringWithFormat:@"sys: %@", info[@"sys"]];
    _lblState.text = [NSString stringWithFormat:@"state: %@", info[@"state"]];
    _lblBitrate.text = [NSString stringWithFormat:@"bitrate: %ld", [info[@"bitrate"] longValue]];
    _lblUrl.text = [NSString stringWithFormat:@"url: %@", info[@"url"]];
    _lblFps.text = [NSString stringWithFormat:@"fps: %ld", [info[@"fps"] longValue]];
    _lblSDKVersion.text = [NSString stringWithFormat:@"ver: %@", info[@"sdk"]];
    _lblPlatform.text = [NSString stringWithFormat:@"pla: %@", info[@"platform"]];
}

- (void)getBitrate
{
    NSString *bitrate = @"";
    if ([[CameraServer server] outBitrate].length == 0) {
        bitrate = @"0";
    } else {
        bitrate = [[CameraServer server] outBitrate];
    }
    self.lblBitrate.text = [NSString stringWithFormat:@"bitrate:%@", bitrate];
    
    _lblCpu.text = [NSString stringWithFormat:@"CPU: %.2f%%", [self getCpuUsage]];
}


- (void)show:(NSString *)publishUrl
{
    CameraServer *ucdLiveEngine = [CameraServer server];
    
    struct utsname systemInfo;
    uname(&systemInfo);
    NSString *platform = [NSString stringWithCString:systemInfo.machine encoding:NSUTF8StringEncoding];
    
    NSString *bitrate = @"";
    if ([ucdLiveEngine outBitrate].length == 0) {
        bitrate = @"0";
    } else {
        bitrate = [ucdLiveEngine outBitrate];
    }
    
    NSDictionary *logDict =@{
                             @"cpu" : @([self getCpuUsage]),
                             @"bitrate" : @([bitrate longLongValue]),
                             @"fps" : @(ucdLiveEngine.fps),
                             @"state" : @(0),
                             @"sys" : [[UIDevice currentDevice] systemVersion],
                             @"platform" : platform,
                             @"sdk" : [ucdLiveEngine getSDKVersion],
                             @"url" : publishUrl
                             };
    
    [self showInfo:logDict];
}

- (void)updateState:(NSNotification *)notification
{
    NSDictionary *dict = notification.object;
    _lblState.text = [NSString stringWithFormat:@"state: %ld", [dict[@"state"] longValue]];
}


- (float)getCpuUsage
{
    kern_return_t kr;
    task_info_data_t tinfo;
    mach_msg_type_number_t task_info_count;
    
    task_info_count = TASK_INFO_MAX;
    kr = task_info(mach_task_self(), TASK_BASIC_INFO, (task_info_t)tinfo, &task_info_count);
    if (kr != KERN_SUCCESS) {
        return -1;
    }
    
    task_basic_info_t      basic_info;
    thread_array_t         thread_list;
    mach_msg_type_number_t thread_count;
    
    thread_info_data_t     thinfo;
    mach_msg_type_number_t thread_info_count;
    
    thread_basic_info_t basic_info_th;
    uint32_t stat_thread = 0; // Mach threads
    
    basic_info = (task_basic_info_t)tinfo;
    
    // get threads in the task
    kr = task_threads(mach_task_self(), &thread_list, &thread_count);
    if (kr != KERN_SUCCESS) {
        return -1;
    }
    if (thread_count > 0)
        stat_thread += thread_count;
    
    long tot_sec = 0;
    long tot_usec = 0;
    float tot_cpu = 0;
    int j;
    
    for (j = 0; j < thread_count; j++)
    {
        thread_info_count = THREAD_INFO_MAX;
        kr = thread_info(thread_list[j], THREAD_BASIC_INFO,
                         (thread_info_t)thinfo, &thread_info_count);
        if (kr != KERN_SUCCESS) {
            return -1;
        }
        
        basic_info_th = (thread_basic_info_t)thinfo;
        
        if (!(basic_info_th->flags & TH_FLAGS_IDLE)) {
            tot_sec = tot_sec + basic_info_th->user_time.seconds + basic_info_th->system_time.seconds;
            tot_usec = tot_usec + basic_info_th->user_time.microseconds + basic_info_th->system_time.microseconds;
            tot_cpu = tot_cpu + basic_info_th->cpu_usage / (float)TH_USAGE_SCALE * 100.0;
        }
        
    } // for each thread
    
    kr = vm_deallocate(mach_task_self(), (vm_offset_t)thread_list, thread_count * sizeof(thread_t));
    assert(kr == KERN_SUCCESS);
    
    return tot_cpu;
}

#pragma mark - infoView subviews
- (UILabel *)lblBitrate
{
    if (!_lblBitrate) {
        _lblBitrate = [[UILabel alloc]initWithFrame:CGRectMake(2, 0, 200, 25)];
    }
    return _lblBitrate;
}

- (UILabel *)lblFps
{
    if (!_lblFps) {
        _lblFps = [[UILabel alloc]initWithFrame:CGRectMake(CGRectGetWidth(_lblBitrate.frame), 0, 200, 25)];
    }
    return _lblFps;
}

- (UILabel *)lblState
{
    if (!_lblState) {
        _lblState = [[UILabel alloc]initWithFrame:CGRectMake(2, CGRectGetHeight(_lblBitrate.frame), 200, 25)];
    }
    return _lblState;
}

- (UILabel *)lblSys
{
    if (!_lblSys) {
        _lblSys = [[UILabel alloc]initWithFrame:CGRectMake(2, CGRectGetHeight(_lblState.frame) * 2, 200, 25)];
    }
    return _lblSys;
}

- (UILabel *)lblSDKVersion
{
    if (!_lblSDKVersion) {
        _lblSDKVersion = [[UILabel alloc]initWithFrame:CGRectMake(CGRectGetWidth(_lblState.frame), CGRectGetHeight(_lblState.frame) * 2, 200, 25)];
    }
    return _lblSDKVersion;
}

- (UILabel *)lblCpu
{
    if (!_lblCpu) {
        _lblCpu = [[UILabel alloc]initWithFrame:CGRectMake(2, CGRectGetHeight(_lblSys.frame) * 3, 200, 25)];
    }
    return _lblCpu;
}

- (UILabel *)lblPlatform
{
    if (!_lblPlatform) {
        _lblPlatform = [[UILabel alloc]initWithFrame:CGRectMake(CGRectGetWidth(_lblCpu.frame), CGRectGetHeight(_lblSys.frame) * 3, 200, 25)];
    }
    return _lblPlatform;
}

- (UILabel *)lblUrl
{
    if (!_lblUrl) {
        _lblUrl = [[UILabel alloc]initWithFrame:CGRectMake(2, CGRectGetHeight(_lblCpu.frame) * 4, self.frame.size.width - 4, 50)];
        _lblUrl.numberOfLines = 2;
    }
    return _lblUrl;
}

@end
