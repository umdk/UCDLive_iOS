//
//  UCDLiveDemoHeader.h
//  UCDLiveDemo-V2
//
//  Created by Sidney on 26/04/17.
//  Copyright © 2017年 https://ucloud.cn. All rights reserved.
//

#ifndef UCDLiveDemoHeader_h
#define UCDLiveDemoHeader_h


// demo中的推流地址仅供demo测试使用，如果更换推流域名地址，请发邮件至spt_sdk@ucloud.cn或联系客服、客户经理索取对应的AccessKey
#define AccessKey @"publish3-key"
// 此ID仅供demo连麦测试使用，需要发邮件至spt_sdk@ucloud.cn或联系客服、客户经理对接相关ID值
#define RTCAPPid @"f6da0ba61b7d409280d3623320c425ba"

/**
 *  注意 关于推流路径和播放路径设置
 *  要修改textField中的推流ID同时保证推流端和播放端的ID是一样的，不能多个手机使用一个推流路径，可以多个手机播放一个路径
 */

//****************测试线路1****************
#define RecordDomainOne @"rtmp://publish3.cdn.ucloud.com.cn/ucloud/%@";
//【推荐】使用http-flv作为直播播放必须设置urltype为UrlTypeLive，详见PlayerManager.m
#define PlayDomainOne @"http://vlive3.rtmp.cdn.ucloud.com.cn/ucloud/%@.flv";
//#define PlayDomainOne @"rtmp://vlive3.rtmp.cdn.ucloud.com.cn/ucloud/%@";
//#define PlayDomainOne @"http://vlive3.hls.cdn.ucloud.com.cn/ucloud/%@/playlist.m3u8";


//****************测试线路2****************
#define RecordDomainTwo @"rtmp://publish3.usmtd.ucloud.com.cn/live/%@";
//【推荐】使用http-flv作为直播播放必须设置urltype为UrlTypeLive，详见PlayerManager.m
#define PlayDomainTwo @"http://rtmp3.usmtd.ucloud.com.cn/live/%@.flv";
//#define PlayDomainTwo @"rtmp://rtmp3.usmtd.ucloud.com.cn/live/%@";
//#define PlayDomainTwo @"http://hls3.usmtd.ucloud.com.cn/live/%@/playlist.m3u8";

//主要单例
#define UserDefaults [NSUserDefaults standardUserDefaults]
#define NotificationCenter [NSNotificationCenter defaultCenter]
#define SharedApplication [UIApplication sharedApplication]
#define Bundle [NSBundle mainBundle]#define MainScreen [UIScreen mainScreen]

// rgb颜色转换（16进制->10进制）
#define UIColorFromRGB(rgbValue) [UIColor colorWithRed:((float)((rgbValue & 0xFF0000) >> 16))/255.0 green:((float)((rgbValue & 0xFF00) >> 8))/255.0 blue:((float)(rgbValue & 0xFF))/255.0 alpha:1.0]

#define ToryBlue UIColorFromRGB(0x0D58A6)
#define CelestialBlue UIColorFromRGB(0x4188D2)
#define BlueGray UIColorFromRGB(0x689CD2)
#define DarkMidnightBlue UIColorFromRGB(0x04376C)

#endif /* UCDLiveDemoHeader_h */
