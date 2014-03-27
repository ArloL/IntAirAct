#import "IAModelReference.h"

#import "IANumber.h"

@implementation IAModelReference

- (BOOL)isEqual:(id)object
{
    if (self == object) {
        return YES;
    }

    if (object == nil || ![object isKindOfClass:[self class]]) {
        return NO;
    }

    IAModelReference * model = (IAModelReference*) object;
    return (self.number == model.number || [self.number isEqual:model.number]);
}

-(NSString *)description
{
    return [NSString stringWithFormat:@"IAModelReference: [number: %@]", self.number];
}

@end
