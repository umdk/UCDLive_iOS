//
//  RTCMenuViewController.m
//  UCDLiveDemo-V2
//
//  Created by Sidney on 23/05/17.
//  Copyright © 2017年 https://ucloud.cn. All rights reserved.
//

#import "RTCMenuViewController.h"
#import "RTCLiveViewController.h"

@interface RTCMenuViewController ()

@property (weak, nonatomic) IBOutlet UITextField *textFieldRoom;
@end

@implementation RTCMenuViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    
    //随机一个房间号
    srand((unsigned)time(NULL));
#if DEBUG
    NSInteger num = 4391;
#else
    NSInteger num = rand()%10000;
#endif
    
    self.textFieldRoom.text = [NSString stringWithFormat:@"%ld", (long)num];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
    
//    _isPortrait = YES;
    if ([segue.destinationViewController isKindOfClass:[RTCLiveViewController class]]) {
        RTCLiveViewController *publishVC = segue.destinationViewController;
        publishVC.roomId = self.textFieldRoom.text;
        publishVC.publishUrl = [NSString stringWithFormat:@"rtmp://publish3.cdn.ucloud.com.cn/ucloud/%@", publishVC.roomId];
    }
    
}
    
- (void)touchesBegan:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event
{
    [self.view endEditing:YES];
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
