/** Representation of a device capability. */
@interface IACapability : NSObject

/** The description of the capability.
 
 An example could be: "GET /images".
 */
@property (strong) NSString * capability;

+(IACapability *)capability:(NSString *) capability;

@end
