#import "IARequest.h"

@implementation IARequest

-(id)initWithRoute:(IARoute *)route metadata:(NSDictionary *)metadata parameters:(NSDictionary *)parameters origin:(IADevice *)origin body:(NSData *)body
{
    self = [super init];
    if (self) {
        _route = route;
        _metadata = metadata;
        _parameters = parameters;
        _origin = origin;
        _body = _body;
    }
    return self;
}

-(NSString *)metadata:(NSString *)field
{
    return self.metadata[field];
}

-(id)parameter:(NSString *)name
{
    return self.parameters[name];
}

-(NSString *)description
{
    return [NSString stringWithFormat:@"IARequest[route: %@, metadata: %@, parameters: %@, origin: %@]", self.route, self.metadata, self.parameters, self.origin];
}

@end
