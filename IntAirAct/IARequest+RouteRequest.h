#import <IntAirAct/IntAirAct.h>

@interface IARequest (RouteRequest)

+(IARequest*)requestWithRouteRequest:(RouteRequest *)routeRequest origin:(IADevice*)origin route:(IARoute*)route;

@end
