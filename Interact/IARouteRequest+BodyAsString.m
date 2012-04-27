#import "IARouteRequest+BodyAsString.h"

@implementation RouteRequest (BodyAsString)

-(NSString *)bodyAsString
{
    return [[NSString alloc] initWithBytes:[[self body] bytes] length:[[self body] length] encoding:NSUTF8StringEncoding];
}

@end
