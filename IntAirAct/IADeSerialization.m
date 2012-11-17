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
    NSError * error;
    id result = [self.body objectFromJSONDataWithParseOptions:0 error:&error];
    if (error) {
        IALogError(@"Error ocurred while serializing: %@", error);
        return nil;
    }

    return [self deserialize:result class:class];
}

-(id)deserialize:(id)data class:(Class)class
{
    if ([data isKindOfClass:NSClassFromString(@"JKArray")]) {
        NSMutableArray * array = [NSMutableArray new];
        for (id obj in data) {
            [array addObject:[self deserialize:obj class:class]];
        }
        return array;
    } else{
        id obj = [class new];
        unsigned int outCount, i;
        objc_property_t *properties = class_copyPropertyList(class, &outCount);
        for(i = 0; i < outCount; i++) {
            objc_property_t property = properties[i];
            const char *propName = property_getName(property);
            if(propName) {
                NSString *propertyName = [NSString stringWithUTF8String:propName];
                [obj setValue:data[propertyName] forKey:propertyName];
            }
        }
        free(properties);
        return obj;
    }
}

-(void)setBodyWith:(id)data
{
    if([data isKindOfClass:[NSString class]]) {
        [self setBodyWithString:data];
    } else if([data isKindOfClass:[NSNumber class]]) {
        [self setBodyWithString:[NSString stringWithFormat:@"%@", data]];
    } else {
        id serializedObject = [self serialize:data];
        NSError * error;
        NSData * result = [serializedObject JSONDataWithOptions:0 error:&error];
        if (error) {
            IALogError(@"Error ocurred while serializing: %@", error);
        } else {
            [self setBodyWithData:result];
        }
    }
}

-(id)serialize:(id)data
{
    if (data == nil) {
        return nil;
    } else if ([data isKindOfClass:[NSString class]] || [data isKindOfClass:[NSNumber class]]) {
        return data;
    } else if ([data isKindOfClass:[NSArray class]] || [data isKindOfClass:[NSSet class]]) {
        NSMutableArray * array = [NSMutableArray new];
        for (id obj in data) {
            [array addObject:[self serialize:obj]];
        }
        return array;
    } else if ([data isKindOfClass:[NSDictionary class]]) {
        NSMutableDictionary * dic = [NSMutableDictionary new];
        [data enumerateKeysAndObjectsUsingBlock:^(id key, id obj, BOOL *stop) {
            dic[[self serialize:key]] = [self serialize:obj];
        }];
        return dic;
    } else if ([data isKindOfClass:[NSObject class]]) {
        // find the names of all the properties
        NSMutableDictionary * dic = [NSMutableDictionary new];
        unsigned int outCount, i;
        objc_property_t *properties = class_copyPropertyList([data class], &outCount);
        for(i = 0; i < outCount; i++) {
            objc_property_t property = properties[i];
            const char *propName = property_getName(property);
            if(propName) {
                NSString *propertyName = [NSString stringWithUTF8String:propName];
                [dic setValue:[self serialize:[data valueForKey:propertyName]] forKey:propertyName];
            }
        }
        free(properties);

        if (dic.count == 0) {
            return data;
        } else {
            return dic;
        }
    } else {
        return data;
    }
}

-(NSString *)bodyAsString
{
    return [[NSString alloc] initWithBytes:[self.body bytes] length:[self.body length] encoding:NSUTF8StringEncoding];
}

- (void)setBodyWithString:(NSString *)string {
    self.body = [string dataUsingEncoding:NSUTF8StringEncoding];
}

- (void)setBodyWithData:(NSData *)data {
    self.body = data;
}

@end
