/** Representation of a Device found on the network */
@interface IADevice : NSObject

+(IADevice*)deviceWithName:(NSString*)name host:(NSString*)host port:(NSInteger)port supportedRoutes:(NSSet*)supportedRoutes;

-(id)initWithName:(NSString*)name host:(NSString*)host port:(NSInteger)port supportedRoutes:(NSSet*)supportedRoutes;

/** The supported routes of the device */
@property (strong, readonly) NSSet * supportedRoutes;

/** The host of the device. */
@property (strong, readonly) NSString * host;

/** The name of the device. */
@property (strong, readonly) NSString * name;

/** The port on which the device is running IntAirAct */
@property (readonly) NSInteger port;

@end
