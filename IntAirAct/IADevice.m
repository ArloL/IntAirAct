#import "IADevice.h"

@implementation IADevice

@synthesize name = _name;
@synthesize host = _host;
@synthesize port = _port;

-(id)copy
{
    IADevice * res = [IADevice new];
    res.name = self.name;
    res.host = self.host;
    res.port = self.port;
    return res;
}

-(NSString *)hostAndPort
{
    return [NSString stringWithFormat:@"http://%@:%i", self.host, self.port];
}

-(NSString *)description
{
    return [NSString stringWithFormat:@"IADevice[name: %@, hostAndPort: %@]", self.name, self.hostAndPort];
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
