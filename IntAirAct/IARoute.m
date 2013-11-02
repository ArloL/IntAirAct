#import "IARoute.h"

@implementation IARoute

// Short-hand constructors for custom routes.
+(IARoute*)put:(NSString*)resource
{
    return [[IARoute alloc] initWithAction:@"PUT" resource:resource];
}

+(IARoute*)post:(NSString*)resource
{
    return [[IARoute alloc] initWithAction:@"POST" resource:resource];
}

+(IARoute*)get:(NSString*)resource
{
    return [[IARoute alloc] initWithAction:@"GET" resource:resource];
}

+(IARoute*)delete:(NSString*)resource
{
    return [[IARoute alloc] initWithAction:@"DELETE" resource:resource];
}

+(IARoute*)routeWithAction:(NSString*)action resource:(NSString*)resource
{
    return [[IARoute alloc] initWithAction:action resource:resource];
}

- (id)initWithAction:(NSString *)action resource:(NSString*)resource
{
    self = [super init];
    if (self) {
        _action = action;
        _resource = resource;
    }
    return self;
}

-(NSString *)description
{
    return [NSString stringWithFormat:@"IARoute[action: %@, resource: %@]", self.action, self.resource];
}

-(BOOL)isEqual:(id)object
{
    if (self == object) {
        return YES;
    }

    if (object == nil || ![object isKindOfClass:[self class]]) {
        return NO;
    }

    IARoute * route = (IARoute*) object;
    return (self.action == route.action || [self.action isEqual:route.action])
        && (self.resource == route.resource || [self.resource isEqual:route.resource]);
}

-(NSUInteger)hash
{
    NSUInteger hash = 66;
    hash = hash * 31 + self.action.hash;
    hash = hash * 31 + self.resource.hash;
    return hash;
}

@end
