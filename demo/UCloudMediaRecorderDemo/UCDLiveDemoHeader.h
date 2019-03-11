//
//  UCDLiveDemoHeader.h
//  UCloudMediaRecorderDemo
//
//  Created by Sidney on 26/04/17.
//  Copyright © 2017年 https://ucloud.cn. All rights reserved.
//

#ifndef UCDLiveDemoHeader_h
#define UCDLiveDemoHeader_h


/**
 *  注意 关于推流路径和播放路径设置
 *  要修改textField中的推流ID同时保证推流端和播放端的ID是一样的，不能多个手机使用一个推流路径，可以多个手机播放一个路径
 */

/**
 *可以找云厂商（优刻得、阿里云,腾讯云等）创建直播服务
 **/
//****************测试线路1****************
#define RecordDomainOne @"";
//【推荐】使用http-flv作为直播播放必须设置urltype为UrlTypeLive，详见PlayerManager.m
#define PlayDomainOne @"";



//****************测试线路2****************
#define RecordDomainTwo @"";
//【推荐】使用http-flv作为直播播放必须设置urltype为UrlTypeLive，详见PlayerManager.m
#define PlayDomainTwo @"";


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

