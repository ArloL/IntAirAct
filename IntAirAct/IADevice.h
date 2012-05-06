@interface IADevice : NSObject

@property (nonatomic, strong) NSSet * capabilities;
@property (nonatomic, strong) NSString * host;
@property (nonatomic, strong, readonly) NSString * hostAndPort;
@property (nonatomic, strong) NSString * name;
@property (nonatomic) NSInteger port;

@end
