#import "IADevice.h"

@implementation IADevice

@synthesize capabilities;
@synthesize host;
@synthesize name;
@synthesize port;

-(id)copy
{
    IADevice * res = [IADevice new];
    res.capabilities = [self.capabilities copy];
    res.host = self.host;
    res.name = self.name;
    res.port = self.port;
    return res;
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
