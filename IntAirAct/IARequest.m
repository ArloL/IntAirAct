#import "IARequest.h"

@implementation IARequest

@synthesize body = _body;

+(IARequest *)requestWithRoute:(IARoute *)route metadata:(NSDictionary *)metadata parameters:(NSDictionary *)parameters origin:(IADevice *)origin body:(NSData *)body
{
    return [[IARequest alloc] initWithRoute:route metadata:metadata parameters:parameters origin:origin body:body];
}

-(id)initWithRoute:(IARoute *)route metadata:(NSDictionary *)metadata parameters:(NSDictionary *)parameters origin:(IADevice *)origin body:(NSData *)body
{
    self = [super init];
    if (self) {
        _route = route;
        _metadata = metadata;
        _parameters = parameters;
        _origin = origin;
        _body = body;
    }
    return self;
}

-(NSString *)description
{
    return [NSString stringWithFormat:@"IARequest[route: %@, metadata: %@, parameters: %@, origin: %@]", self.route, self.metadata, self.parameters, self.origin];
}

@end
