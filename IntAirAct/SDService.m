#import "SDService.h"

@implementation SDService

+(SDService*)serviceWithName:(NSString *)name hostName:(NSString *)hostName port:(NSInteger)port
{
    return [[SDService alloc] initWithName:name hostName:hostName port:port];
}

- (id)init
{
    self = [super init];
    if (self) {
        @throw [NSException exceptionWithName:NSInternalInconsistencyException reason:@"-init is not a valid initializer for the class SDService" userInfo:nil];
    }
    return self;
}

-(id)initWithName:(NSString *)name hostName:(NSString *)hostName port:(NSInteger)port
{
    self = [super init];
    if (self) {
        _name = name;
        _hostName = hostName;
        _port = port;
    }
    return self;
}

-(NSString *)description
{
    return [NSString stringWithFormat:@"SDService[name: %@, host: %@, port: %"FMTNSINT"]", self.name, self.hostName, self.port];
}

-(BOOL)isEqual:(id)other
{
    if([other isKindOfClass:[SDService class]]) {
        SDService * service = other;
        return [self.name isEqualToString:service.name];
    }
    return [super isEqual:other];
}

-(NSUInteger)hash
{
    return [self.name hash];
}

@end
