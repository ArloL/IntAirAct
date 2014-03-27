#import "IAModelWithFloat.h"

@implementation IAModelWithFloat

- (BOOL)isEqual:(id)object
{
    if (self == object) {
        return YES;
    }

    if (object == nil || ![object isKindOfClass:[self class]]) {
        return NO;
    }

    IAModelWithFloat * model = (IAModelWithFloat*) object;
    return (self.floatProperty == model.floatProperty);
}

-(NSString *)description
{
    return [NSString stringWithFormat:@"IAModelWithFloat: [floatProperty: %f]", self.floatProperty];
}

@end
