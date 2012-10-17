#import "RouteResponse+IAResponse.h"

#import "IAResponse.h"

@implementation RouteResponse (IAResponse)

-(void)copyValuesFromIAResponse:(IAResponse *)iaResponse;
{
    self.statusCode = [iaResponse.statusCode integerValue];
    [self respondWithData:iaResponse.body];
    [iaResponse.metadata enumerateKeysAndObjectsUsingBlock:^(id key, id obj, BOOL *stop) {
        [self setHeader:key value:obj];
    }];
}

@end
