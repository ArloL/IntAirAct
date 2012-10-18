#import <RoutingHTTPServer/RouteResponse.h>

@class IAResponse;

@interface RouteResponse (IAResponse)

-(void)copyValuesFromIAResponse:(IAResponse *)iaResponse;

@end
