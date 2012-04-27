#import "IAAction.h"

@implementation IAAction

@synthesize action = _action;
@synthesize parameters = _parameters;

-(NSString *)description
{
    return [NSString stringWithFormat:@"IAAction[action: %@, parameters: %@]", self.action, self.parameters];
}

@end
