#import "IARequest+RouteRequest.h"

#import <RoutingHTTPServer/RouteRequest.h>

@implementation IARequest (RouteRequest)

+(IARequest*)requestWithRouteRequest:(RouteRequest *)routeRequest origin:(IADevice*)origin route:(IARoute*)route
{
    NSMutableDictionary * metadata = [NSMutableDictionary new];
    [routeRequest.headers enumerateKeysAndObjectsUsingBlock:^(id key, id obj, BOOL *stop) {
        metadata[key] = [obj stringByReplacingPercentEscapesUsingEncoding:NSISOLatin1StringEncoding];
    }];
    NSMutableDictionary * parameters = [NSMutableDictionary dictionaryWithDictionary:routeRequest.params];
    NSData * body = routeRequest.body;
    return [[IARequest alloc] initWithRoute:route metadata:metadata parameters:parameters origin:origin body:body];
}

@end
