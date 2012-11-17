#import "IAModelWithInt.h"

@implementation IAModelWithInt

- (BOOL)isEqual:(id)object
{
    if (self == object) {
        return YES;
    }
    
    if (object == nil || ![object isKindOfClass:[self class]]) {
        return NO;
    }
    
    IAModelWithInt * model = (IAModelWithInt*) object;
    return (self.intProperty == model.intProperty);
}

-(NSString *)description
{
    return [NSString stringWithFormat:@"IAModelWithInt: [intProperty: %i]", self.intProperty];
}

@end
