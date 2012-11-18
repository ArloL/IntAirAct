#import "IARequest+RouteRequest.h"

#import <RoutingHTTPServer/RouteRequest.h>

@implementation IARequest (RouteRequest)

+(IARequest*)requestWithRouteRequest:(RouteRequest *)routeRequest origin:(IADevice*)origin route:(IARoute*)route
{
    NSMutableDictionary * metadata = [NSMutableDictionary dictionaryWithDictionary:routeRequest.headers];
    NSMutableDictionary * parameters = [NSMutableDictionary dictionaryWithDictionary:routeRequest.params];
    NSData * body = routeRequest.body;
    return [[IARequest alloc] initWithRoute:route metadata:metadata parameters:parameters origin:origin body:body];
}

@end
