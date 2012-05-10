#import "IANumber.h"

@implementation IANumber

@synthesize number;

-(BOOL)isEqual:(id)object
{
    if([object isKindOfClass:[self class]]) {
        return [self.number isEqual:((IANumber *)object).number];
    } else {
        return [super isEqual:object];
    }
}

-(NSUInteger)hash
{
    return [self.number hash];
}

-(NSString *)description
{
    return [NSString stringWithFormat:@"IANumber: [number: %@]", self.number];
}

@end
