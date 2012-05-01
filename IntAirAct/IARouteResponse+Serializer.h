#import <RoutingHTTPServer/RoutingHTTPServer.h>

@class IAIntAirAct;

@interface RouteResponse (Serializer)

-(void)respondWith:(id)data withIntAirAct:(IAIntAirAct *)intAirAct;

@end
