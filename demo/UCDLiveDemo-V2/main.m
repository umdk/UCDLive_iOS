//
//  main.m
//  UCDLiveDemo-V2
//
//  Created by Sidney on 07/02/17.
//  Copyright © 2017年 https://ucloud.cn. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "AppDelegate.h"
#import "ZJLogManger.h"

int main(int argc, char * argv[]) {
    @autoreleasepool {
        [ZJLogManger shareManger];
        return UIApplicationMain(argc, argv, nil, NSStringFromClass([AppDelegate class]));
    }
}
