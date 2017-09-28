//
//  ViewController.m
//  UCloudMediaRecorderDemo
//
//  Created by Sidney on 07/02/17.
//  Copyright © 2017年 https://ucloud.cn. All rights reserved.
//

#import "ViewController.h"
#import "LUNSegmentedControl.h"
#import "RTCLiveViewController.h"
#import "PlayViewController.h"

#import "UCDLiveDemoHeader.h"

typedef NS_ENUM(NSUInteger, LiveType) {
    LiveTypeRtmp,
    LiveTypeRTC,
};


@interface ViewController ()<LUNSegmentedControlDelegate, LUNSegmentedControlDataSource>
{
    NSArray *routeTitles, *directionTitles, *bitrateTitles, *liveTypes;
}

@property (weak, nonatomic) IBOutlet LUNSegmentedControl *segmentedControlRoute;
@property (weak, nonatomic) IBOutlet LUNSegmentedControl *segmentedControlDirection;
@property (weak, nonatomic) IBOutlet LUNSegmentedControl *segmentedControlBitrate;
@property (weak, nonatomic) IBOutlet LUNSegmentedControl *segmentedControlLiveType;

@property (weak, nonatomic) IBOutlet UITextField *textFieldFPS;
@property (weak, nonatomic) IBOutlet UITextField *textFieldPublishID;

@property (weak, nonatomic) IBOutlet UIButton *btnPublish;
@property (weak, nonatomic) IBOutlet UIButton *btnPlay;
@property (weak, nonatomic) IBOutlet UIButton *btnDeputy;

@property (strong, nonatomic) NSString *route;
@property (assign, nonatomic) UCloudVideoOrientation direction;
@property (assign, nonatomic) UCloudVideoBitrate bitrate;
@property (assign, nonatomic) LiveType liveType;

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
    _direction = _direction?_direction:UCloudVideoOrientationPortrait;
    _liveType = LiveTypeRtmp;
    self.btnDeputy.hidden = YES;
    
    routeTitles = @[@"Line1", @"Line2"];
    directionTitles = @[@"vertical", @"horizontal"];
    bitrateTitles = @[@"Low", @"Normal", @"Medium", @"High"];
    liveTypes = @[@"直播", @"连麦"];
    self.segmentedControlRoute.dataSource = self;
    self.segmentedControlDirection.dataSource = self;
    self.segmentedControlBitrate.dataSource = self;
    self.segmentedControlLiveType.dataSource = self;
    
    [_btnPublish setBackgroundImage:[self imageWithColor:DarkMidnightBlue] forState:UIControlStateHighlighted];
    [_btnPlay setBackgroundImage:[self imageWithColor:DarkMidnightBlue] forState:UIControlStateHighlighted];
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
    
    _segmentedControlRoute.currentState = 1;
    _segmentedControlLiveType.currentState = 1;;
    _segmentedControlDirection.currentState = 1;
}

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    switch (_bitrate) {
        case UCloudVideoBitrateLow:
            _segmentedControlBitrate.currentState = 0;
            break;
        case UCloudVideoBitrateNormal:
            _segmentedControlBitrate.currentState = 1;
            break;
        case UCloudVideoBitrateMedium:
            _segmentedControlBitrate.currentState = 2;
            break;
        case UCloudVideoBitrateHigh:
            _segmentedControlBitrate.currentState = 3;
            break;
        default:
            break;
    }
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
        playerVC.playUrl = [NSString stringWithFormat:_route, _textFieldPublishID.text];
    }

}

- (void)touchesBegan:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event
{
    [self.view endEditing:YES];
}

#pragma mark - LUNSegmentedControlDataSource

- (NSArray<UIColor *> *)segmentedControl:(LUNSegmentedControl *)segmentedControl gradientColorsForStateAtIndex:(NSInteger)index {
    switch (index) {
        case 0:
            return @[BlueGray];
            
            break;
            
        case 1:
            return @[CelestialBlue];
            break;
            
        case 2:
            return @[ToryBlue];
            break;
            
        default:
            return @[DarkMidnightBlue];
            break;
    }
    return nil;
}

- (NSInteger)numberOfStatesInSegmentedControl:(LUNSegmentedControl *)segmentedControl {
    if (segmentedControl.tag == 3) {
        return 4;
    }

    return 2;
}

- (NSString *)segmentedControl:(LUNSegmentedControl *)segmentedControl titleForStateAtIndex:(NSInteger)index
{
    NSString *titlePrefix = @"";
    if (segmentedControl.tag == 1) {
        titlePrefix = routeTitles[index];
    } else if (segmentedControl.tag == 2) {
        titlePrefix = directionTitles[index];
    } else if (segmentedControl.tag == 3)  {
        titlePrefix = bitrateTitles[index];
    } else  {
        titlePrefix = liveTypes[index];
    }
    return titlePrefix;
}

- (NSString *)segmentedControl:(LUNSegmentedControl *)segmentedControl titleForSelectedStateAtIndex:(NSInteger)index
{
    NSString *titlePrefix = @"";
    if (segmentedControl.tag == 1) {
        titlePrefix = routeTitles[index];
    } else if (segmentedControl.tag == 2) {
        titlePrefix = directionTitles[index];
    } else if (segmentedControl.tag == 3) {
        titlePrefix = bitrateTitles[index];
    } else {
        titlePrefix = liveTypes[index];
    }
    return titlePrefix;
}

- (void)segmentedControl:(LUNSegmentedControl *)segmentedControl didChangeStateFromStateAtIndex:(NSInteger)fromIndex toStateAtIndex:(NSInteger)toIndex
{
    if (segmentedControl.tag == 1) {
        if (toIndex == 0) {
            self.route = RecordDomainOne;
        } else {
            self.route = RecordDomainTwo;
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
    } else {
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
    }

}

- (IBAction)btnPlayTouchUpInside:(id)sender {
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
