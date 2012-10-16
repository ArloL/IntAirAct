#import "IAAction.h"

@implementation IAAction

-(NSString *)description
{
    return [NSString stringWithFormat:@"IAAction[action: %@, parameters: %@]", self.action, self.parameters];
}

@end
