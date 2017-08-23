//
//  InfoView.h
//  UCloudMediaRecorderDemo
//
//  Created by Sidney on 24/04/17.
//  Copyright © 2017年 https://ucloud.cn. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface InfoView : UIView

@property (strong, nonatomic) UILabel *lblBitrate;
@property (strong, nonatomic) UILabel *lblFps;
@property (strong, nonatomic) UILabel *lblState;
@property (strong, nonatomic) UILabel *lblSys;
@property (strong, nonatomic) UILabel *lblSDKVersion;
@property (strong, nonatomic) UILabel *lblCpu;
@property (strong, nonatomic) UILabel *lblPlatform;
@property (strong, nonatomic) UILabel *lblUrl;

- (void)show:(NSString *)publishUrl;

@end
