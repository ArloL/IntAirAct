#import <RoutingHTTPServer/RoutingHTTPServer.h>

@class IAResponse;

@interface RouteResponse (IAResponse)

-(void)copyValuesFromIAResponse:(IAResponse *)iaResponse;

@end
