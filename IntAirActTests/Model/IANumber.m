#import "IANumber.h"

@implementation IANumber

- (BOOL)isEqual:(id)object
{
    if (self == object) {
        return YES;
    }

    if (object == nil || ![object isKindOfClass:[self class]]) {
        return NO;
    }

    IANumber * model = (IANumber*) object;
    return (self.number == model.number || [self.number isEqual:model.number]);
}

-(NSString *)description
{
    return [NSString stringWithFormat:@"IANumber: [number: %@]", self.number];
}

@end
