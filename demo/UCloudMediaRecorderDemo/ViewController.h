//
//  ViewController.h
//  UCloudMediaRecorderDemo
//
//  Created by yisanmao on 15-3-18.
//  Copyright (c) 2015年 yisanmao. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "CameraServer.h"
#import "UCloudMediaPlayer.h"
#import "UCloudMediaViewController.h"
#import "PlayerManager.h"

//demo中的推流地址仅供demo测试使用，如果更换推流域名地址，请发邮件至spt_sdk@ucloud.cn或联系客服、客户经理索取对应的AccessKey
#define AccessKey @"publish3-key"


/*
 ****************测试线路1****************
 */
#define RecordDomainOne(id) [NSString stringWithFormat:@"rtmp://publish3.cdn.ucloud.com.cn/ucloud/%@", id];
//【推荐】使用http-flv作为直播播放必须设置urltype为UrlTypeLive，详见PlayerManager.m
#define PlayDomainOne(id) [NSString stringWithFormat:@"http://vlive3.rtmp.cdn.ucloud.com.cn/ucloud/%@.flv", id];
//#define PlayDomainOne(id) [NSString stringWithFormat:@"rtmp://vlive3.rtmp.cdn.ucloud.com.cn/ucloud/%@", id];
//#define PlayDomainOne(id) [NSString stringWithFormat:@"http://vlive3.hls.cdn.ucloud.com.cn/ucloud/%@/playlist.m3u8", id];


/*
 ****************测试线路2****************
 */
#define RecordDomainTwo(id) [NSString stringWithFormat:@"rtmp://publish3.usmtd.ucloud.com.cn/live/%@", id];
//【推荐】使用http-flv作为直播播放必须设置urltype为UrlTypeLive，详见PlayerManager.m
#define PlayDomainTwo(id) [NSString stringWithFormat:@"http://rtmp3.usmtd.ucloud.com.cn/live/%@.flv", id];
//#define PlayDomainTwo(id) [NSString stringWithFormat:@"rtmp://rtmp3.usmtd.ucloud.com.cn/live/%@", id];
//#define PlayDomainTwo(id) [NSString stringWithFormat:@"http://hls3.usmtd.ucloud.com.cn/live/%@/playlist.m3u8", id];


@interface ViewController : UIViewController<UITextFieldDelegate>

@property (strong, nonatomic) PlayerManager *playerManager;

- (void)setBtnStateInSel:(NSInteger)num;
- (BOOL)checkPath;

@end
