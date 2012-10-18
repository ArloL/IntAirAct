#import "IADevice.h"

@implementation IADevice

+(IADevice *)deviceWithName:(NSString *)name host:(NSString *)host port:(NSInteger)port capabilities:(NSSet *)capabilities
{
    return [[IADevice alloc] initWithName:name host:host port:port capabilities:capabilities];
}

- (id)initWithName:(NSString*)name host:(NSString*)host port:(NSInteger)port capabilities:(NSSet*)capabilities
{
    self = [super init];
    if (self) {
        _capabilities = capabilities;
        _name = name;
        _host = host;
        _port = port;
    }
    return self;
}

- (id)init
{
    self = [super init];
    if (self) {
        @throw [NSException exceptionWithName:NSInternalInconsistencyException reason:@"-init is not a valid initializer for the class IADevice" userInfo:nil];
    }
    return self;
}

-(id)copy
{
    return [IADevice deviceWithName:self.name host:self.host port:self.port capabilities:[self.capabilities copy]];
}

-(NSString *)description
{
    return [NSString stringWithFormat:@"IADevice[name: %@, host: %@, port: %"FMTNSINT", capabilities: %@]", self.name, self.host, self.port, self.capabilities];
}

-(BOOL)isEqual:(id)object
{
    if([object isKindOfClass:[IADevice class]]) {
        IADevice * device = object;
        return [self.name isEqualToString:device.name];
    }
    return [super isEqual:object];
}

-(NSUInteger)hash
{
    return [self.name hash];
}

@end
