#import "NSURLRequest+IARequest.h"

#import "NSURL+QueryParameters.h"
#import "IADevice.h"
#import "IARequest.h"
#import "IARoute.h"
#import "IALogging.h"

// Log levels: off, error, warn, info, verbose
// Other flags: trace
static const int intAirActLogLevel = IA_LOG_LEVEL_WARN; // | IA_LOG_FLAG_TRACE

@implementation NSURLRequest (IARequest)

+(NSURLRequest *)requestWithIARequest:(IARequest *)request andDevice:(IADevice*)device
{
    NSString * resource = [self replaceParametersIn:request.route.resource with:request.parameters];
    NSURL * url = [NSURL URLWithString:[NSString stringWithFormat:@"http://%@:%"FMTNSINT"%@", device.host, device.port, resource]];
    url = [url URLByAppendingQueryParameters:request.parameters];
    NSMutableURLRequest * urlRequest = [NSMutableURLRequest requestWithURL:url];
    urlRequest.HTTPMethod = request.route.action;
    urlRequest.HTTPBody = request.body;
    [urlRequest setAllHTTPHeaderFields:request.metadata];
    [urlRequest addValue:request.origin.name forHTTPHeaderField:@"X-IA-Origin"];
    return urlRequest;
}

+(NSString*)replaceParametersIn:(NSString*)path with:(NSMutableDictionary*)parameters
{
    // Parse any :parameters in the path
    NSRegularExpression *regex = [NSRegularExpression regularExpressionWithPattern:@"(\\{(\\w+)\\})"
                                                      options:0
                                                        error:nil];
    NSMutableString *regexPath = [NSMutableString stringWithString:path];
    __block NSInteger diff = 0;
    [regex enumerateMatchesInString:path
                            options:0
                              range:NSMakeRange(0, path.length)
                         usingBlock:^(NSTextCheckingResult *result, NSMatchingFlags flags, BOOL *stop) {
                             NSRange replacementRange = NSMakeRange(diff + result.range.location, result.range.length);
                             NSString *keyString = [path substringWithRange:[result rangeAtIndex:2]];
                             if (parameters[keyString]) {
                                 NSString * replacementString = parameters[keyString];
                                 replacementString = [replacementString stringByAddingPercentEscapesUsingEncoding:NSASCIIStringEncoding];
                                 IALogVerbose(@"%@[%p]: Replacing parameter %@ with %@", THIS_FILE, self, keyString, replacementString);
                                 [regexPath replaceCharactersInRange:replacementRange withString:replacementString];
                                 diff += replacementString.length - result.range.length;
                                 [parameters removeObjectForKey:keyString];
                             }
                         }];
    
    return [regexPath copy];
}

@end
