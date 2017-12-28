//
//  RTCLiveViewController.h
//  UCloudMediaRecorderDemo
//
//  Created by Sidney on 23/05/17.
//  Copyright © 2017年 https://ucloud.cn. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "CameraServer.h"
#import "NSString+UCloudCameraCode.h"
#import "FilterManager.h"

/*!
 *  连麦中的角色
 */
typedef NS_ENUM(NSInteger, UCDRtcRole) {
    Role_Anchor, //主播
    Role_VICE_Anchor //副主播
};



@interface RTCLiveViewController : UIViewController

@property (assign, nonatomic) int fps;
@property (strong, nonatomic) NSString *route;
@property (assign, nonatomic) UCloudVideoOrientation direction;
@property (assign, nonatomic) UCloudVideoBitrate bitrate;
@property (assign, nonatomic) UCloudAudioNoiseSuppress noiseSuppress;
@property (strong, nonatomic) NSString *publishUrl;
@property (strong, nonatomic) NSString *roomId;
@property (assign, nonatomic) BOOL isPortrait;
@property (assign, nonatomic) UCDRtcRole rtcRole;


@end
