// TODO: remove this line
#import <UIKit/UIKit.h>

@interface AgoraVideoSource : NSObject

/*
 timeStamp: in milliseconds
 rotation: use following calculation

 int degrees = [self getDisplayRotation];
 int rotation;
 if(isFrontCamera) {
     rotation = (cameraOrientation + degrees + 360) % 360;
 }
 else {
     rotation = (cameraOrientation - degrees + 360) % 360;
 }

 where cameraOrientation == 90

 - (int) getDisplayRotation
 {
     UIInterfaceOrientation orientation = [UIApplication sharedApplication].statusBarOrientation;
     switch(orientation) {
     case UIDeviceOrientationPortrait:
     default:
         return 0;
     case UIDeviceOrientationLandscapeLeft:
         return 90;
     case UIDeviceOrientationPortraitUpsideDown:
         return 180;
     case UIDeviceOrientationLandscapeRight:
         return 270;
     }
 }

 */

-(void) Attach;
-(void) Detach;
// deprecated; use DeliverFrame instead
- (void)SendFrameNV21:(void *)nv21 width:(int)width height:(int)height rotation:(int)rotation timeStamp:(long long)ts;
// deprecated; use DeliverFrame instead
- (void)SendFrameI420:(void *)i420 width:(int)width height:(int)height rotation:(int)rotation timeStamp:(long long)ts;
// deprecated; use DeliverFrame instead
- (void)SendFrameBGRA:(void *)bgra width:(int)width height:(int)height rotation:(int)rotation timeStamp:(long long)ts;
/** Input a frame to engine
 *
 * width, height: size of 'buf' in pixels
 * cropLeft: how many pixels to crop on the left boundary
 * cropTop: how many pixels to crop on the top boundary
 * cropRight: how many pixels to crop on the right boundary
 * cropBottom: how many pixels to crop on the bottom boundary
 * rotation: 0, 90, 180, 270. See document for rotation calculation
 * ts: timestamp for this frame. in milli-second
 * format: 1: I420 2: ARGB 3: NV21 4: RGBA
 *
 * width/height/cropLeft/cropTop/cropRight/cropBottom: specifying the rotated buffer,
 * not pre-rotate buffer
 */
- (void)DeliverFrame:(void *)buf width:(int)width height:(int)height
	cropLeft:(int)cropLeft cropTop:(int)cropTop cropRight:(int)cropRight cropBottom:(int)cropBottom
	rotation:(int)rotation timeStamp:(long long)ts format:(int)format;

- (void)DeliverTexture:(CVPixelBufferRef)texBuf rotation:(int)rotation timeStamp:(long long)ts;

@end
