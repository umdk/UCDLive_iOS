//
//  ZJLogManger.h
//  RunTime
//
//  Created by foscom on 16/7/12.
//  Copyright © 2016年 zengjia. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface ZJLogManger : NSObject

/**
 *  NSLog文件重定向
 *
 */


+ (id)shareManger;

@property (nonatomic, assign)BOOL XcodeOutput;  // xcode 调试时是否输出到文件  默认 NO
@property (nonatomic, assign)BOOL SimulatorOutput;   // 模拟器下是否输出到文件  默认 NO
@property (nonatomic, assign)BOOL SenderlogToEmail;  // 默认 NO

@end
