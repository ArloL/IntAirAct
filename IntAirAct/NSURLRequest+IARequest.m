#import "NSURLRequest+IARequest.h"

#import "NSURL+QueryParameters.h"
#import "IADevice.h"
#import "IARequest.h"
#import "IARoute.h"

@implementation NSURLRequest (IARequest)

+(NSURLRequest *)requestWithIARequest:(IARequest *)request andDevice:(IADevice*)device
{
    NSURL * url = [NSURL URLWithString:[NSString stringWithFormat:@"http://%@:%"FMTNSINT"%@", device.host, device.port, request.route.resource]];
    url = [url URLByAppendingQueryParameters:request.parameters];
    NSMutableURLRequest * urlRequest = [NSMutableURLRequest requestWithURL:url];
    urlRequest.HTTPMethod = request.route.action;
    urlRequest.HTTPBody = request.body;
    [urlRequest setAllHTTPHeaderFields:request.metadata];
    [urlRequest addValue:request.origin.name forHTTPHeaderField:@"X-IA-Source"];
    return urlRequest;
}

@end
