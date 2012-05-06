#import "NSMutableArray+KeyValueCoding.h"

@implementation NSMutableArray (KeyValueCoding)

-(void)setValue:(id)value forKey:(NSString *)key
{
    NSUInteger index = [key integerValue];
    if(index > [self count]) {
        [self addObject:value];
    } else {
        [self replaceObjectAtIndex:index withObject:value];
    }
}

-(id)valueForKey:(NSString *)key
{
    NSUInteger index = [key integerValue];
    return [self objectAtIndex:index];
}

@end
