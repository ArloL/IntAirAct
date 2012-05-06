#import "IACapability.h"

@implementation IACapability

@synthesize capability;

-(NSString *)description
{
    return [NSString stringWithFormat:@"IACapability: [capability: %@]", self.capability];
}

-(BOOL)isEqual:(id)object
{
    if([object isKindOfClass:[IACapability class]]) {
        IACapability * other = object;
        return [other.capability isEqualToString:self.capability];
    }
    return [super isEqual:object];
}

-(NSUInteger)hash
{
    return [self.capability hash];
}

@end
