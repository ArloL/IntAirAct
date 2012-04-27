#import <UIKit/UIKit.h>
#import <CoreLocation/CoreLocation.h>
#import <CoreMotion/CoreMotion.h>

@interface IALocator : NSObject<CLLocationManagerDelegate, UIAccelerometerDelegate>

-(void)startTracking;
-(CLLocationDirection)currentHeading;
-(CLLocation *)currentLocation;
-(UIInterfaceOrientation)currentOrientation;
-(CMDeviceMotion *)deviceMotion;
-(float)realAngle:(float)angle;

@end
