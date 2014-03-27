#import "IAModelWithString.h"

@implementation IAModelWithString

- (BOOL)isEqual:(id)object
{
    if (self == object) {
        return YES;
    }

    if (object == nil || ![object isKindOfClass:[self class]]) {
        return NO;
    }

    IAModelWithString * model = (IAModelWithString*) object;
    return (self.stringProperty == model.stringProperty || [self.stringProperty isEqual:model.stringProperty]);
}

-(NSString *)description
{
    return [NSString stringWithFormat:@"IAModelWithString: [stringProperty: %@]", self.stringProperty];
}

@end
