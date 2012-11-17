#import "IAModelInheritance.h"

@implementation IAModelInheritance

- (BOOL)isEqual:(id)object
{
    if (self == object) {
        return YES;
    }
    
    if (object == nil || ![object isKindOfClass:[self class]]) {
        return NO;
    }
    
    IAModelInheritance * model = (IAModelInheritance*) object;
    return (self.number == model.number || [self.number isEqual:model.number])
        && (self.numberTwo == model.numberTwo || [self.numberTwo isEqual:model.numberTwo]);
}

-(NSString *)description
{
    return [NSString stringWithFormat:@"IAModelInheritance: [number: %@, numberTwo: %@]", self.number, self.numberTwo];
}

@end
