#import <RoutingHTTPServer/RoutingHTTPServer.h>

@class IAInteract;

@interface RouteResponse (Serializer)

-(void)respondWith:(id)data withInteract:(IAInteract *)interact;

@end
