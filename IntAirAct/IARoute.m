#import "IARoute.h"

@implementation IARoute

+(IARoute*)imageRoute
{
    return [[IARoute alloc] initWithAction:@"PUT" resource:@"/image"];
}

+(IARoute*)textRoute
{
    return [[IARoute alloc] initWithAction:@"PUT" resource:@"/text"];
}

+(IARoute*)videoRoute
{
    return [[IARoute alloc] initWithAction:@"PUT" resource:@"/video"];
}

// Short-hand constructors for custom routes.
+(IARoute*)putRoute:(NSString*)resource
{
    return [[IARoute alloc] initWithAction:@"PUT" resource:resource];
}

+(IARoute*)postRoute:(NSString*)resource
{
    return [[IARoute alloc] initWithAction:@"POST" resource:resource];
}

+(IARoute*)getRoute:(NSString*)resource
{
    return [[IARoute alloc] initWithAction:@"GET" resource:resource];
}

+(IARoute*)deleteRoute:(NSString*)resource
{
    return [[IARoute alloc] initWithAction:@"DELETE" resource:resource];
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
    return [NSString stringWithFormat:@"IARouter[action: %@, resource: %@]", self.action, self.resource];
}


@end
