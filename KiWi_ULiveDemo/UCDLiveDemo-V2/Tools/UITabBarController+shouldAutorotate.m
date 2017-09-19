//
//  UITabBarController+shouldAutorotate.m
//  DartsDistribute
//
//  Created by Maxson-001 on 14-9-9.
//  Copyright (c) 2014年 Maxson-001. All rights reserved.
//

#import "UITabBarController+shouldAutorotate.h"

@implementation UITabBarController (shouldAutorotate)

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    return [self.selectedViewController shouldAutorotateToInterfaceOrientation:interfaceOrientation];
}

- (BOOL)shouldAutorotate
{
    return self.selectedViewController.shouldAutorotate;
}

- (NSUInteger)supportedInterfaceOrientations
{
    return self.selectedViewController.supportedInterfaceOrientations;
}

- (UIStatusBarStyle)preferredStatusBarStyle {
    return self.selectedViewController.preferredStatusBarStyle;
}

@end
