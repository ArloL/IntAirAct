#import "IAResponse+Generic.h"

#import <UIKit/UIKit.h>
#import <RestKit/JSONKit.h>
#import <objc/runtime.h>

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
    } else {
        id mappedObj = [self mapObject:data];

        // i have to create the native type
        NSError * error;
        NSData * result = [mappedObj JSONDataWithOptions:0 error:&error];
        if (error) {
            IALogError(@"Error ocurred while serializing: %@", error);
        } else {
            [self respondWithData:result];
        }
    }
}

-(id)mapObject:(id)data
{
    if ([data isKindOfClass:[NSArray class]]) {
        NSMutableArray * array = [NSMutableArray new];
        for (id obj in data) {
            [array addObject:[self mapObject:obj]];
        }
        return array;
    } else {
        // find the names of all the properties
        NSMutableDictionary * dic = [NSMutableDictionary new];
        unsigned int outCount, i;
        objc_property_t *properties = class_copyPropertyList([data class], &outCount);
        for(i = 0; i < outCount; i++) {
            objc_property_t property = properties[i];
            const char *propName = property_getName(property);
            if(propName) {
                NSString *propertyName = [NSString stringWithUTF8String:propName];
                [dic setValue:[data valueForKey:propertyName] forKey:propertyName];
            }
        }
        free(properties);

        return dic;
    }
}

@end
