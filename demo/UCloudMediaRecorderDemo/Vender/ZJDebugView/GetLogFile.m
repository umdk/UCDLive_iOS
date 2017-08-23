//
//  GetLogFile.m
//  RunTime
//
//  Created by foscom on 16/7/12.
//  Copyright © 2016年 zengjia. All rights reserved.
//

#import "GetLogFile.h"
@implementation GetLogFile

- (void)getLogFileData:(void (^)(NSString *,NSString *))logBlock
{
    
    NSString *Path = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES)[0];
    NSString *logPath = [Path stringByAppendingPathComponent:@"Log"];
    
   if([[NSFileManager defaultManager] fileExistsAtPath:logPath])
   {
       NSArray *arr = nil;       
     arr =  [[NSFileManager defaultManager] contentsOfDirectoryAtPath:logPath error:nil];
       
       
    arr = [arr sortedArrayUsingComparator:^NSComparisonResult(id  _Nonnull obj1, id  _Nonnull obj2) {
       return [obj1 compare:obj2];
    }];
     
       NSString *filepath = [logPath stringByAppendingPathComponent:[arr lastObject]];
       
       NSData *data = [NSData dataWithContentsOfFile:filepath];
       
       NSString *str = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
       
       if (logBlock) {
           logBlock(str,filepath);
       }
 
   }
    
    
}

@end
