// TODO: remove this line
#import <UIKit/UIKit.h>

typedef NS_ENUM(NSInteger, AgoraEnhancerType) {
    AgoraEnhancerTypeNone = -1,
    AgoraEnhancerTypeGPU = 0,
    AgoraEnhancerTypeGPUNFLS = 1,
    AgoraEnhancerTypeGPUBG = 2,
    AgoraEnhancerTypeCPUNFLS = 3,
    AgoraEnhancerTypeCPUBG = 4,
};

@interface AgoraYuvEnhancerObjc : NSObject
@property (assign, nonatomic) CGFloat colortemperature;
@property (assign, nonatomic) CGFloat lighteningFactor;
@property (assign, nonatomic) CGFloat smoothness;
@property (assign, nonatomic) CGFloat gammaFactor;
@property (assign, nonatomic) AgoraEnhancerType type;

- (void)turnOn;
- (void)turnOff;
@end
