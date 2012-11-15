#import "IAResponse+Generic.h"

#import <UIKit/UIKit.h>

#import "IAResponse+Image.h"
#import "IALogging.h"

// Log levels: off, error, warn, info, verbose
// Other flags: trace
static const int intAirActLogLevel = IA_LOG_LEVEL_VERBOSE; // | IA_LOG_FLAG_TRACE

@implementation IAResponse (Generic)

-(void)respondWith:(id)data
{
    if([data isKindOfClass:[UIImage class]]) {
        [self respondWithImage:data];
    } else if ([data isKindOfClass:[NSArray class]]) {
#warning serialization not implemented
        [self respondWithString:@"[]"];
    }
}

@end
