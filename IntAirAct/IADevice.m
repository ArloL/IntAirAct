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
    return [NSString stringWithFormat:@"IADevice[name: %@, host: %@, port: %li, supportedRoutes: %@]", self.name, self.host, (long)self.port, self.supportedRoutes];
}

- (BOOL)isEqual:(id)object
{
    if (self == object) {
        return YES;
    }

    if (object == nil || ![object isKindOfClass:[self class]]) {
        return NO;
    }

    IADevice * service = (IADevice*) object;
    return (self.name == service.name || [self.name isEqual:service.name]);
}

- (NSUInteger)hash
{
    NSUInteger hash = 830;
    hash = hash * 31 + self.name.hash;
    return hash;
}

@end
