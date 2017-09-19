//
//  PublishViewController.h
//  UCDLiveDemo-V2
//
//  Created by Sidney on 19/04/17.
//  Copyright © 2017年 https://ucloud.cn. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "CameraServer.h"
#import "NSString+UCloudCameraCode.h"
#import "FilterManager.h"
#import "KWSDK.h"
#import "KWSDK_UI.h"


@interface PublishViewController : UIViewController

@property (assign, nonatomic) int fps;
@property (strong, nonatomic) NSString *route;
@property (assign, nonatomic) UCloudVideoOrientation direction;
@property (assign, nonatomic) UCloudVideoBitrate bitrate;
@property (strong, nonatomic) NSString *publishUrl;
@property (assign, nonatomic) BOOL isPortrait;
/**
 sdk UI action object
 */
@property (nonatomic, strong) KWSDK_UI *kwSdkUI;

@end
