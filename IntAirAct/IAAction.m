#import "IAAction.h"

@implementation IAAction

@synthesize action;
@synthesize parameters;

-(NSString *)description
{
    return [NSString stringWithFormat:@"IAAction[action: %@, parameters: %@]", self.action, self.parameters];
}

@end
