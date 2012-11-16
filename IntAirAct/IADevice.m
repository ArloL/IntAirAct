#import "IADevice.h"

@implementation IADevice

+(IADevice *)deviceWithName:(NSString *)name host:(NSString *)host port:(NSInteger)port supportedRoutes:(NSSet *)supportedRoutes
{
    return [[IADevice alloc] initWithName:name host:host port:port supportedRoutes:supportedRoutes];
}

- (id)initWithName:(NSString*)name host:(NSString*)host port:(NSInteger)port supportedRoutes:(NSSet*)supportedRoutes
{
    self = [super init];
    if (self) {
        _supportedRoutes = supportedRoutes;
        _name = name;
        _host = host;
        _port = port;
    }
    return self;
}

-(NSString *)description
{
    return [NSString stringWithFormat:@"IADevice[name: %@, host: %@, port: %"FMTNSINT", supportedRoutes: %@]", self.name, self.host, self.port, self.supportedRoutes];
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
