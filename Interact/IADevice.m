#import "IADevice.h"

@implementation IADevice

@synthesize name = _name;
@synthesize hostAndPort = _hostAndPort;

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
