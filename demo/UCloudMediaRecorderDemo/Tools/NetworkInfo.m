//
//  NetworkInfo.m
//  UCloudMediaRecorderDemo
//
//  Created by Sidney on 26/04/17.
//  Copyright © 2017年 https://ucloud.cn. All rights reserved.
//

#import "NetworkInfo.h"
#include <sys/socket.h>
#include <net/if.h>
#import <SystemConfiguration/CaptiveNetwork.h>
#include <objc/runtime.h>
#import <ifaddrs.h>
#import <arpa/inet.h>
#import <NetworkExtension/NEHotspotHelper.h>

@interface NetworkInfo()
    
@property (assign, nonatomic) double upWiFi;
@property (assign, nonatomic) double downWiFi;
@property (assign, nonatomic) double upGPRS;
@property (assign, nonatomic) double downGPRS;

@end


@implementation NetworkInfo
    
-(NSDictionary*) getDataFlowBytes {
    NSString *const DataCounterKeyWWANSent = @"WWANSent";
    NSString *const DataCounterKeyWWANReceived = @"WWANReceived";
    NSString *const DataCounterKeyWiFiSent = @"WiFiSent";
    NSString *const DataCounterKeyWiFiReceived = @"WiFiReceived";
    
    struct ifaddrs *addrs;
    const struct ifaddrs *cursor;
    
    u_int32_t WiFiSent = 0;
    u_int32_t WiFiReceived = 0;
    u_int32_t WWANSent = 0;
    u_int32_t WWANReceived = 0;
    
    if (getifaddrs(&addrs) == 0) {
        cursor = addrs;
        while (cursor != NULL)
        {
            if (cursor->ifa_addr->sa_family == AF_LINK)
            {
                /*
                 const struct if_data *ifa_data = (struct if_data *)cursor->ifa_data;
                 if(ifa_data != NULL)
                 {
                 NSLog(@"Interface name %s: sent %tu received %tu",cursor->ifa_name,ifa_data->ifi_obytes,ifa_data->ifi_ibytes);
                 }
                 */
                
                // name of interfaces:
                // en0 is WiFi (provides network bytes exchanges and not just internet)
                // lo0 is WiFi
                // pdp_ip0 is WWAN
                NSString *name = [NSString stringWithFormat:@"%s",cursor->ifa_name];
                if ([name hasPrefix:@"en"])
                {
                    const struct if_data *ifa_data = (struct if_data *)cursor->ifa_data;
                    if(ifa_data != NULL)
                    {
                        WiFiSent += ifa_data->ifi_obytes;
                        WiFiReceived += ifa_data->ifi_ibytes;
                    }
                }
                if ([name hasPrefix:@"pdp_ip"])
                {
                    const struct if_data *ifa_data = (struct if_data *)cursor->ifa_data;
                    if(ifa_data != NULL)
                    {
                        WWANSent += ifa_data->ifi_obytes;
                        WWANReceived += ifa_data->ifi_ibytes;
                    }
                }
            }
            cursor = cursor->ifa_next;
        }
        freeifaddrs(addrs);
    }
    
    return @{DataCounterKeyWiFiSent:[NSNumber numberWithUnsignedInt:WiFiSent],
             DataCounterKeyWiFiReceived:[NSNumber numberWithUnsignedInt:WiFiReceived],
             DataCounterKeyWWANSent:[NSNumber numberWithUnsignedInt:WWANSent],
             DataCounterKeyWWANReceived:[NSNumber numberWithUnsignedInt:WWANReceived]};
}
    
- (instancetype)init
{
    self = [super init];
    if (self) {
        NSDictionary *dict = [self getDataFlowBytes];
        self.upWiFi = [dict[@"WiFiSent"] doubleValue];
        self.downWiFi = [dict[@"WiFiReceived"] doubleValue];
        self.upGPRS = [dict[@"WWANSent"] doubleValue];
        self.downGPRS = [dict[@"WWANReceived"] doubleValue];
        self.dt = 1.0;
    }
    return self;
}

- (void)update
{
    double up1 = _upGPRS + _upWiFi;
    double down1 = _downGPRS + _downWiFi;
    double cell1 = _upGPRS + _downGPRS;
    double wifi1 = _upWiFi + _downWiFi;
    
    NSDictionary *dict = [self getDataFlowBytes];
    self.upWiFi = [dict[@"WiFiSent"] doubleValue];
    self.downWiFi = [dict[@"WiFiReceived"] doubleValue];
    self.upGPRS = [dict[@"WWANSent"] doubleValue];
    self.downGPRS = [dict[@"WWANReceived"] doubleValue];
    
    double up2 = _upGPRS + _upWiFi;
    double down2 = _downGPRS + _downWiFi;
    double cell2 = _upGPRS + _downGPRS;
    double wifi2 = _upWiFi + _downWiFi;
    
    _upSpeed = (up2 - up1) / _dt;
    _downSpeed = (down2 - down1) / _dt;
    
    _cellularUsed += cell2 - cell1;
    _wifiUsed += wifi2 - wifi1;
    
}


@end
