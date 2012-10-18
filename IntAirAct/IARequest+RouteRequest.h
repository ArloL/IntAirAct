#import "IARequest.h"

@class RouteRequest;

@interface IARequest (RouteRequest)

+(IARequest*)requestWithRouteRequest:(RouteRequest *)routeRequest origin:(IADevice*)origin route:(IARoute*)route;

@end
