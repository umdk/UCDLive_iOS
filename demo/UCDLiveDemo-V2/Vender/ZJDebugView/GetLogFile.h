//
//  GetLogFile.h
//  RunTime
//
//  Created by foscom on 16/7/12.
//  Copyright © 2016年 zengjia. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface GetLogFile : NSObject
@property(nonatomic,assign)int changeValue;

- (void)getLogFileData:(void(^)(NSString *logDataStr,NSString *filepath))logBlock;

@end
