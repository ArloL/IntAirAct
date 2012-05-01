@interface IADevice : NSObject

@property (nonatomic, strong) NSString * name;
@property (nonatomic, strong) NSString * host;
@property (nonatomic, strong, readonly) NSString * hostAndPort;
@property (nonatomic) NSInteger port;

@end
