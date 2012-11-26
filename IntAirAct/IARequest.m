#import "IARequest.h"

@implementation IARequest

+(IARequest *)requestWithRoute:(IARoute *)route
{
    IARequest * request = [IARequest new];
    request.route = route;
    return request;
}

+(IARequest *)requestWithRoute:(IARoute *)route origin:(IADevice *)origin body:(id)data
{
    IARequest * request = [IARequest new];
    request.route = route;
    request.origin = origin;
    [request setBodyWith:data];
    return request;
}

+(IARequest *)requestWithRoute:(IARoute *)route metadata:(NSMutableDictionary *)metadata parameters:(NSMutableDictionary *)parameters origin:(IADevice *)origin body:(NSData *)body
{
    return [[IARequest alloc] initWithRoute:route metadata:metadata parameters:parameters origin:origin body:body];
}

- (id)init
{
    self = [super init];
    if (self) {
        _metadata = [NSMutableDictionary new];
        _parameters = [NSMutableDictionary new];
    }
    return self;
}

-(id)initWithRoute:(IARoute *)route metadata:(NSMutableDictionary *)metadata parameters:(NSMutableDictionary *)parameters origin:(IADevice *)origin body:(NSData *)body
{
    self = [super initWithBody:body];
    if (self) {
        _route = route;
        _metadata = metadata;
        _parameters = parameters;
        _origin = origin;
    }
    return self;
}

-(NSString *)description
{
    return [NSString stringWithFormat:@"IARequest[route: %@, metadata: %@, parameters: %@, origin: %@]", self.route, self.metadata, self.parameters, self.origin];
}

@end
