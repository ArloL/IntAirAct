/** Representation of a Device found on the network */
@interface IADevice : NSObject

+(IADevice*)deviceWithName:(NSString*)name host:(NSString*)host port:(NSInteger)port capabilities:(NSSet*)capabilities;

-(id)initWithName:(NSString*)name host:(NSString*)host port:(NSInteger)port capabilities:(NSSet*)capabilities;

/** The capabilities of the device */
@property (strong, readonly) NSSet * capabilities;

/** The host of the device. */
@property (strong, readonly) NSString * host;

/** The name of the device. */
@property (strong, readonly) NSString * name;

/** The port on which the device is running IntAirAct */
@property (readonly) NSInteger port;

@end
