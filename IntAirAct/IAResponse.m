#import "IAResponse.h"

@implementation IAResponse

- (id)init
{
    self = [super init];
    if (self) {
        _metadata = [NSMutableDictionary new];
        _statusCode = OK;
    }
    return self;
}

-(NSString *)description
{
    return [NSString stringWithFormat:@"IAResponse[statusCode: %@, metadata: %@]", self.statusCode, self.metadata];
}

@end
