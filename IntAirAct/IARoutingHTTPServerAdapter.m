#import "IARoutingHTTPServerAdapter.h"

#import <RoutingHTTPServer/RoutingHTTPServer.h>

#import "IARoute.h"
#import "IARequest.h"
#import "IARequest+RouteRequest.h"
#import "RouteResponse+IAResponse.h"
#import "IAResponse.h"

@interface IARoutingHTTPServerAdapter ()

@property (strong, nonatomic) RoutingHTTPServer* routingHTTPServer;
@property (strong, nonatomic) NSArray * routes;

@end

@implementation IARoutingHTTPServerAdapter

@synthesize port = _port;

-(id)initWithRoutingHTTPServer:(RoutingHTTPServer *)routingHTTPServer
{
    self = [super init];
    if (self) {
        
        _port = 0;
        
        _routingHTTPServer = routingHTTPServer;
        
        // Tell the server to broadcast its presence via ZeroConf.
        [_routingHTTPServer setType:@"_intairact._tcp."];
    }
    return self;
}

- (id)init
{
    self = [super init];
    if (self) {
        @throw [NSException exceptionWithName:NSInternalInconsistencyException reason:@"-init is not a valid initializer for the class IARoutingHTTPServerAdapter" userInfo:nil];
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

-(BOOL)start:(NSError *__autoreleasing *)errPtr
{
    return [self.routingHTTPServer start:errPtr];
}

-(void)stop
{
    [self.routingHTTPServer stop];
}

@end
