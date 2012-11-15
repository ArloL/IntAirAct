#import "NSURL+QueryParameters.h"

@implementation NSURL (QueryParameters)

- (NSURL *)URLByAppendingQueryString:(NSString *)queryString {
    if (![queryString length]) {
        return self;
    }

    NSString * URLString = [NSString stringWithFormat:@"%@%@%@", [self absoluteString], [self query] ? @"&" : @"?", queryString];
    return [NSURL URLWithString:URLString];
}

- (NSURL *)URLByAppendingQueryParameters:(NSDictionary *)parameters {
    if (!parameters.count) {
        return self;
    }

    __block NSString * queryString = nil;
    [parameters enumerateKeysAndObjectsUsingBlock:^(id key, id value, BOOL *stop) {
        NSString * escapedKey = [key stringByAddingPercentEscapesUsingEncoding:NSASCIIStringEncoding];
        NSString * escapedValue = [value stringByAddingPercentEscapesUsingEncoding:NSASCIIStringEncoding];
        if (!queryString) {
            queryString = [NSString stringWithFormat:@"%@=%@", escapedKey, escapedValue];
        } else {
            queryString = [queryString stringByAppendingFormat:@"&%@=%@", escapedKey, escapedValue];
        }
    }];

    return [self URLByAppendingQueryString:queryString];
}

@end
