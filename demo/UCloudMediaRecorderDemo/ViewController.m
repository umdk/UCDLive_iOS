//
//  ViewController.m
//  UCloudMediaRecorderDemo
//
//  Created by Sidney on 07/02/17.
//  Copyright © 2017年 https://ucloud.cn. All rights reserved.
//

#import "ViewController.h"
#import "HMSegmentedControl.h"
#import "RTCLiveViewController.h"
#import "PlayViewController.h"

#import "UCDLiveDemoHeader.h"

typedef NS_ENUM(NSUInteger, LiveType) {
    LiveTypeRtmp,
    LiveTypeRTC,
};


@interface ViewController ()

@property (weak, nonatomic) IBOutlet HMSegmentedControl *segmentedControlRoute;
@property (weak, nonatomic) IBOutlet HMSegmentedControl *segmentedControlDirection;
@property (weak, nonatomic) IBOutlet HMSegmentedControl *segmentedControlBitrate;
@property (weak, nonatomic) IBOutlet HMSegmentedControl *segmentedControlLiveType;
@property (weak, nonatomic) IBOutlet HMSegmentedControl *segmentedControlNoiseLevel;

@property (weak, nonatomic) IBOutlet UITextField *textFieldFPS;
@property (weak, nonatomic) IBOutlet UITextField *textFieldPublishID;

@property (weak, nonatomic) IBOutlet UIButton *btnPublish;
@property (weak, nonatomic) IBOutlet UIButton *btnPlay;
@property (weak, nonatomic) IBOutlet UIButton *btnDeputy;

@property (strong, nonatomic) NSString *route;
@property (strong, nonatomic) NSString *playRoute;
@property (assign, nonatomic) UCloudVideoOrientation direction;
@property (assign, nonatomic) UCloudVideoBitrate bitrate;
@property (assign, nonatomic) LiveType liveType;
@property (assign, nonatomic) UCloudAudioNoiseSuppress noiseSuppress;

@property (assign, nonatomic) BOOL isPortrait;

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view, typically from a nib.
    
    //随机一个推流ID
    srand((unsigned)time(NULL));
    NSInteger num = rand()%10000;
    self.textFieldPublishID.text = [NSString stringWithFormat:@"%ld", (long)num];
    
    //初始化
    _bitrate = _bitrate?_bitrate:UCloudVideoBitrateMedium;
    _route = _route?_route:RecordDomainOne;
    _playRoute = _playRoute?_playRoute:PlayDomainOne;
    _direction = _direction?_direction:UCloudVideoOrientationPortrait;
    _liveType = LiveTypeRtmp;
    self.btnDeputy.hidden = YES;
    
    _segmentedControlRoute.sectionTitles = @[@"Line1", @"Line2"];
    _segmentedControlBitrate.sectionTitles = @[@"Low", @"Normal", @"Medium", @"High"];
    _segmentedControlLiveType.sectionTitles = @[@"直播", @"连麦"];
    _segmentedControlDirection.sectionTitles = @[@"Vertical", @"Horizontal"];
    _segmentedControlNoiseLevel.sectionTitles = @[@"Off", @"Low", @"Medium", @"High", @"Very High"];
    
    [self setSegmentedControl:_segmentedControlRoute];
    [self setSegmentedControl:_segmentedControlBitrate];
    [self setSegmentedControl:_segmentedControlLiveType];
    [self setSegmentedControl:_segmentedControlDirection];
    [self setSegmentedControl:_segmentedControlNoiseLevel];
    
    _segmentedControlBitrate.selectedSegmentIndex = 2;
    _segmentedControlNoiseLevel.selectedSegmentIndex = 2;
    
    [_btnPublish setBackgroundImage:[self imageWithColor:DarkMidnightBlue] forState:UIControlStateHighlighted];
    [_btnPlay setBackgroundImage:[self imageWithColor:DarkMidnightBlue] forState:UIControlStateHighlighted];
}

- (void)setSegmentedControl:(HMSegmentedControl*)segmentedControl
{
    segmentedControl.autoresizingMask = UIViewAutoresizingFlexibleRightMargin | UIViewAutoresizingFlexibleWidth;
    segmentedControl.segmentEdgeInset = UIEdgeInsetsMake(0, 10, 0, 10);
    segmentedControl.selectionStyle = HMSegmentedControlSelectionStyleFullWidthStripe;
    segmentedControl.selectionIndicatorLocation = HMSegmentedControlSelectionIndicatorLocationDown;
    segmentedControl.verticalDividerEnabled = YES;
    segmentedControl.verticalDividerColor = [UIColor blackColor];
    segmentedControl.verticalDividerWidth = 1.0f;
    [segmentedControl setTitleFormatter:^NSAttributedString *(HMSegmentedControl *segmentedControl, NSString *title, NSUInteger index, BOOL selected) {
        NSAttributedString *attString = [[NSAttributedString alloc] initWithString:title attributes:@{NSForegroundColorAttributeName : CelestialBlue}];
        return attString;
    }];
    [segmentedControl addTarget:self action:@selector(segmentedControlChangedValue:) forControlEvents:UIControlEventValueChanged];
}

- (UIImage *)imageWithColor:(UIColor *)color {
    CGRect rect = CGRectMake(0.0f, 0.0f, 1.0f, 1.0f);
    UIGraphicsBeginImageContext(rect.size);
    CGContextRef context = UIGraphicsGetCurrentContext();
    
    CGContextSetFillColorWithColor(context, [color CGColor]);
    CGContextFillRect(context, rect);
    
    UIImage *image = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    
    return image;
}


- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    // 设置导航条的色调 理解为"混合色"
//    self.navigationController.navigationBar.barTintColor = [UIColor colorWithRed:0.303 green:0.617 blue:0.999 alpha:1.000];
    self.navigationController.navigationBar.barTintColor = CelestialBlue;
    }

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
    
    _isPortrait = (_direction == UCloudVideoOrientationPortrait) ? YES : NO;
    if ([segue.destinationViewController isKindOfClass:[RTCLiveViewController class]]) {
        RTCLiveViewController *rtcLiveVC = segue.destinationViewController;
        rtcLiveVC.fps = [_textFieldFPS.text intValue];
        rtcLiveVC.route = _route;
        rtcLiveVC.direction = _direction;
        rtcLiveVC.bitrate = _bitrate;
        rtcLiveVC.noiseSuppress = _noiseSuppress;
        rtcLiveVC.isPortrait = _isPortrait;
        rtcLiveVC.roomId = _textFieldPublishID.text;
        rtcLiveVC.publishUrl = [NSString stringWithFormat:_route, _textFieldPublishID.text];
        if ([segue.identifier isEqualToString:@"VAnchor"]) {
            
            rtcLiveVC.rtcRole = Role_VICE_Anchor;
        }
        else
        {
            rtcLiveVC.rtcRole = Role_Anchor;
        }
    }

    if ([segue.destinationViewController isKindOfClass:[PlayViewController class]]) {
        PlayViewController *playerVC = segue.destinationViewController;
        playerVC.isPortrait = _isPortrait;
        playerVC.playUrl = [NSString stringWithFormat:_playRoute, _textFieldPublishID.text];
    }

}

- (void)touchesBegan:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event
{
    [self.view endEditing:YES];
}

- (IBAction)btnPlayTouchUpInside:(id)sender {
}

- (void)segmentedControlChangedValue:(HMSegmentedControl *)segmentedControl {
    NSLog(@"Selected index %ld (via UIControlEventValueChanged)", (long)segmentedControl.selectedSegmentIndex);

    NSInteger toIndex = segmentedControl.selectedSegmentIndex;

    if (segmentedControl.tag == 1) {
        if (toIndex == 0) {
            self.route = RecordDomainOne;
            self.playRoute = PlayDomainOne;
        } else {
            self.route = RecordDomainTwo;
            self.playRoute = PlayDomainTwo;
        }
    } else if (segmentedControl.tag == 2) {
        if (toIndex == 0) {
            self.direction = UCloudVideoOrientationPortrait;
        } else {
            self.direction = UCloudVideoOrientationLandscapeRight;
        }
    } else if (segmentedControl.tag == 4) {
        if (toIndex == 0) {
            self.liveType = LiveTypeRtmp;
            self.btnDeputy.hidden = YES;
        } else {
            self.liveType = LiveTypeRTC;
            self.btnDeputy.hidden = NO;
        }
    } else if (segmentedControl.tag == 3) {
        switch (toIndex) {
            case 0:
                self.bitrate = UCloudVideoBitrateLow;
                break;
            case 1:
                self.bitrate = UCloudVideoBitrateNormal;
                break;
            case 2:
                self.bitrate = UCloudVideoBitrateMedium;
                break;
            case 3:
                self.bitrate = UCloudVideoBitrateHigh;
                break;
            default:
                self.bitrate = UCloudVideoBitrateMedium;
                break;
        }
    } else {
        switch (toIndex) {
            case 0:
                self.noiseSuppress = UCloudAudioNoiseSuppressOff;
                break;
            case 1:
                self.noiseSuppress = UCloudAudioNoiseSuppressLow;
                break;
            case 2:
                self.noiseSuppress = UCloudAudioNoiseSuppressMedium;
                break;
            case 3:
                self.noiseSuppress = UCloudAudioNoiseSuppressHigh;
                break;
            default:
                self.noiseSuppress = UCloudAudioNoiseSuppressMedium;
                break;
    }
}

}

#pragma mark - Orientation

- (BOOL)shouldAutorotate{
    //是否允许转屏
    
    return YES;
}

- (UIInterfaceOrientationMask)supportedInterfaceOrientations
{
    return UIInterfaceOrientationMaskPortrait;
}

- (UIInterfaceOrientation)preferredInterfaceOrientationForPresentation
{
    return UIInterfaceOrientationPortrait;
}

@end
