#import "IARequest+RouteRequest.h"

@implementation IARequest (RouteRequest)

+(IARequest*)requestWithRouteRequest:(RouteRequest *)routeRequest origin:(IADevice*)origin route:(IARoute*)route
{
    NSDictionary * metadata = routeRequest.headers;
    NSDictionary * parameters = routeRequest.params;
    NSData * body = routeRequest.body;
    return [[IARequest alloc] initWithRoute:route metadata:metadata parameters:parameters origin:origin body:body];
}

@end
