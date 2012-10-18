#import "IAHTTPRouter.h"

#import <RoutingHTTPServer/RoutingHTTPServer.h>

#import "IARoute.h"
#import "IARequest.h"
#import "IARequest+RouteRequest.h"
#import "RouteResponse+IAResponse.h"
#import "IAResponse.h"

@interface IAHTTPRouter ()

@property (strong, nonatomic) RoutingHTTPServer* routingHTTPServer;
@property (strong, nonatomic) NSArray * routes;

@end

@implementation IAHTTPRouter

-(id)initWithRoutingHTTPServer:(RoutingHTTPServer *)routingHTTPServer
{
    self = [super init];
    if (self) {
        _routingHTTPServer = routingHTTPServer;
    }
    return self;
}

-(BOOL)route:(IARoute *)route withHandler:(IARequestHandler)handler
{
    // check if route has already been added
    // do more fancy checking, like * case before /specific case
    // add route to array
    [self.routingHTTPServer handleMethod:route.action withPath:route.resource block:^(RouteRequest * rReq, RouteResponse * rRes) {
        IARequest * iaReq = [IARequest requestWithRouteRequest:rReq origin:nil route:route];
        IAResponse * iaRes = [IAResponse new];
        handler(iaReq, iaRes);
        [rRes copyValuesFromIAResponse:iaRes];
    }];
    return YES;
}

@end
