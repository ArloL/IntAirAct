/**
 A device is a device running IntAirAct found on the network.
 */
@interface IADevice : NSObject

/**
 Construct a new device.

 @param name The name of the device.
 @param hostname The host of the device.
 @param port The port of the device.
 @param supportedRoutes The routes supported by the device.

 @return Returns the new device.
 */
+(IADevice*)deviceWithName:(NSString*)name host:(NSString*)host port:(NSInteger)port supportedRoutes:(NSSet*)supportedRoutes;

/**
 Initialize a new device.

 @param name The name of the device.
 @param hostname The host of the device.
 @param port The port of the device.
 @param supportedRoutes The routes supported by the device.

 @return Returns the new device.
 */
-(id)initWithName:(NSString*)name host:(NSString*)host port:(NSInteger)port supportedRoutes:(NSSet*)supportedRoutes;

/**
 The supported routes of the device.
 */
@property (strong, readonly) NSSet * supportedRoutes;

/**
 The host of the device.
 */
@property (strong, readonly) NSString * host;

/**
 The name of the device.
 */
@property (strong, readonly) NSString * name;

/**
 The port on which the device is listening.
 */
@property (readonly) NSInteger port;

@end
