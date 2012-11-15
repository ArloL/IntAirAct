#import "IADeSerialization.h"

#import <UIKit/UIKit.h>
#import <RestKit/JSONKit.h>
#import <objc/runtime.h>

#import "IALogging.h"

// Log levels: off, error, warn, info, verbose
// Other flags: trace
static const int intAirActLogLevel = IA_LOG_LEVEL_WARN; // | IA_LOG_FLAG_TRACE

@implementation IADeSerialization

-(id)initWithBody:(NSData *)body
{
    self = [super init];
    if (self) {
        _body = body;
    }
    return self;

}

-(id)bodyAs:(Class)class
{
    return nil;
}

-(void)setBodyWith:(id)data
{
    if([data isKindOfClass:[UIImage class]]) {
        [self setBodyWithImage:data];
    } else {
        id mappedObj = [self mapObject:data];

        // i have to create the native type
        NSError * error;
        NSData * result = [mappedObj JSONDataWithOptions:0 error:&error];
        if (error) {
            IALogError(@"Error ocurred while serializing: %@", error);
        } else {
            [self setBodyWithData:result];
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

-(void)setBodyWithImage:(UIImage *)image
{
#warning serialization not implemented
}

-(NSString *)bodyAsString
{
    return [[NSString alloc] initWithBytes:[[self body] bytes] length:[[self body] length] encoding:NSUTF8StringEncoding];
}

- (void)setBodyWithString:(NSString *)string {
	[self setBodyWithString:string encoding:NSUTF8StringEncoding];
}

- (void)setBodyWithString:(NSString *)string encoding:(NSStringEncoding)encoding {
	[self setBodyWithData:[string dataUsingEncoding:encoding]];
}

- (void)setBodyWithData:(NSData *)data {
    self.body = data;
}

@end
