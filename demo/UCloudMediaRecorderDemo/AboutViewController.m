//
//  AboutViewController.m
//  UCloudMediaRecorderDemo
//
//  Created by Sidney on 02/05/17.
//  Copyright © 2017年 https://ucloud.cn. All rights reserved.
//

#import "AboutViewController.h"
#import "CameraServer.h"
#import "UCloudMediaPlayer.h"

@interface AboutViewController ()

@property (weak, nonatomic) IBOutlet UILabel *lblLiveSDKVersion;
@property (weak, nonatomic) IBOutlet UILabel *lblAppVersion;
@property (weak, nonatomic) IBOutlet UILabel *lblPlayerSDKVersion;


@end

@implementation AboutViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    
    NSDictionary *infoDictionary = [[NSBundle mainBundle] infoDictionary];
    _lblAppVersion.text = [NSString stringWithFormat:@"App版本：%@(%@)", infoDictionary[@"CFBundleShortVersionString"], infoDictionary[@"CFBundleVersion"]];
    
    _lblLiveSDKVersion.text = [NSString stringWithFormat:@"LiveSDK版本：%@", [CameraServer server].getSDKVersion];
    _lblPlayerSDKVersion.text = [NSString stringWithFormat:@"PlayerSDK版本：%@", [[UCloudMediaPlayer ucloudMediaPlayer] getSDKVersion]];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/
- (IBAction)btnGithubTouchUpInside:(id)sender {
    NSString* strIdentifier = @"https://github.com/umdk/UCDLive_iOS";
    BOOL isExsit = [[UIApplication sharedApplication] canOpenURL:[NSURL URLWithString:strIdentifier]];
    if(isExsit) {
        NSLog(@"App %@ installed", strIdentifier);
        [[UIApplication sharedApplication] openURL:[NSURL URLWithString:strIdentifier]];
    }
}

- (IBAction)btnUrlTouchUpInside:(id)sender {
    
    NSString* strIdentifier = @"https://www.ucloud.cn";
    BOOL isExsit = [[UIApplication sharedApplication] canOpenURL:[NSURL URLWithString:strIdentifier]];
    if(isExsit) {
        NSLog(@"App %@ installed", strIdentifier);
        [[UIApplication sharedApplication] openURL:[NSURL URLWithString:strIdentifier]];
    }
}

- (IBAction)btnTelTouchUpInside:(id)sender {
    
    NSString *phoneNum = @"4000188113";// 电话号码
    UIWebView *phoneCallWebView;
    NSURL *phoneURL = [NSURL URLWithString:[NSString stringWithFormat:@"tel:%@",phoneNum]];
    if ( !phoneCallWebView ) {
        phoneCallWebView = [[UIWebView alloc] initWithFrame:CGRectZero];// 这个webView只是一个后台的View 不需要add到页面上来
        }
    [phoneCallWebView loadRequest:[NSURLRequest requestWithURL:phoneURL]];
    
    [self.view addSubview:phoneCallWebView];
}

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
