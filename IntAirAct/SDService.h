@interface SDService : NSObject

+(SDService*)serviceWithName:(NSString*)name hostName:(NSString*)hostName port:(NSInteger)port;

-(id)initWithName:(NSString*)name hostName:(NSString*)hostName port:(NSInteger)port;

@property (strong, readonly) NSString * name;
@property (strong, readonly) NSString * hostName;
@property (readonly) NSInteger port;

@end
