#import "IARequest.h"

@interface IARequest (JSON)

// application/json
- (NSDictionary*)bodyAsDictionary;

@end
