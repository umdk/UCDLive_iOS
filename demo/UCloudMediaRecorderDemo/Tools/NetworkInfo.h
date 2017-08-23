//
//  NetworkInfo.h
//  UCloudMediaRecorderDemo
//
//  Created by Sidney on 26/04/17.
//  Copyright © 2017年 https://ucloud.cn. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface NetworkInfo : NSObject
    
@property (assign, nonatomic) double upSpeed;
@property (assign, nonatomic) double downSpeed;
@property (assign, nonatomic) double wifiUsed;
@property (assign, nonatomic) double cellularUsed;
@property (assign, nonatomic) double dt;
    
-(NSDictionary*) getDataFlowBytes;

- (void)update;
    
@end
