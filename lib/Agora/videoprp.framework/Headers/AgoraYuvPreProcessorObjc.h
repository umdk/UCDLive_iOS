// TODO: remove this line
#import <UIKit/UIKit.h>

@protocol YuvPreProcessorProtocol <NSObject>

// modify this frame in this callback
@required
- (void)onFrameAvailable:(unsigned char *)y ubuf:(unsigned char *)u vbuf:(unsigned char *)v ystride:(int)ystride ustride:(int)ustride vstride:(int)vstride width:(int)width height:(int)height;

@end

@interface YuvPreProcessor : NSObject

@property (nonatomic, weak) id<YuvPreProcessorProtocol> delegate;

// enable preprocessor
- (void)turnOn;
// disable preprocessor
- (void)turnOff;

@end
