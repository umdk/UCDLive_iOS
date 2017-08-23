//
//  PlayViewController.h
//  UCDVodDemo-V2
//
//  Created by Sidney on 16/03/17.
//  Copyright © 2017年 https://ucloud.cn. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

@interface PlayViewController : UIViewController

@property (weak, nonatomic) IBOutlet UIView *sdlView;
@property (weak, nonatomic) IBOutlet UIButton *btnStop;
@property (weak, nonatomic) IBOutlet UIView *hudView;

@property (strong, nonatomic) NSString *playUrl;
@property (assign, nonatomic) BOOL isPortrait;

- (IBAction)btnStopTouchUpInside:(id)sender;

@end
