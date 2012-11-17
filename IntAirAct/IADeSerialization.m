#import "IADeSerialization.h"

#import <UIKit/UIKit.h>
#import <objc/runtime.h>
#import "JSONKit.h"

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
    if ([class isSubclassOfClass:[NSString class]]) {
        return self.bodyAsString;
    } else if([class isSubclassOfClass:[NSNumber class]]) {
        NSNumberFormatter * f = [NSNumberFormatter new];
        return [f numberFromString:self.bodyAsString];
    } else {
        NSError * error;
        id result = [self.body objectFromJSONDataWithParseOptions:0 error:&error];
        if (error) {
            IALogError(@"Error ocurred while serializing: %@", error);
            return nil;
        }
        return [self deserialize:result class:class];
    }
}

-(id)deserialize:(id)data class:(Class)class
{
    if (data == nil) {
        return nil;
    } else if ([data isKindOfClass:[NSString class]] && [class isSubclassOfClass:[NSString class]]) {
        return data;
    } else if ([data isKindOfClass:[NSNumber class]] && [class isSubclassOfClass:[NSNumber class]]) {
        return data;
    } else if ([data isKindOfClass:NSClassFromString(@"JKDictionary")] && [class isSubclassOfClass:[NSDictionary class]]) {
        NSMutableDictionary * dic = [NSMutableDictionary new];
        [data enumerateKeysAndObjectsUsingBlock:^(id key, id obj, BOOL *stop) {
            dic[key] = obj;
        }];
        return dic;
    } else if ([data isKindOfClass:NSClassFromString(@"JKArray")] && [class isSubclassOfClass:[NSArray class]]) {
        NSMutableArray * array = [NSMutableArray new];
        for (id obj in data) {
            [array addObject:[self deserialize:obj class:class]];
        }
        return array;
    } else {
        id newObj = [class new];
        NSDictionary * properties = [IADeSerialization propertiesWithEncodedTypes:class];
        [properties enumerateKeysAndObjectsUsingBlock:^(id key, id obj, BOOL *stop) {
            NSString * encodedType = obj;
            if ([encodedType isEqual:@"f"]) {
                [newObj setValue:data[key] forKey:key];
            } else if ([encodedType isEqual:@"i"]) {
                [newObj setValue:data[key] forKey:key];
            } else {
                encodedType = [[encodedType substringToIndex:encodedType.length-1] substringFromIndex:2];
                Class class = NSClassFromString(encodedType);
                id value = [self deserialize:data[key] class:class];
                [newObj setValue:value forKey:key];
            }
        }];
        return newObj;
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
            if ([key isKindOfClass:[NSString class]]) {
                dic[key] = [self serialize:obj];
            } else {
                IALogWarn(@"%@: Dictionary key is not a string", THIS_FILE);
            }
        }];
        return dic;
    } else if ([data isKindOfClass:[NSObject class]]) {
        // find the names of all the properties
        NSMutableDictionary * dic = [NSMutableDictionary new];
        NSDictionary * properties = [IADeSerialization propertiesWithEncodedTypes:[data class]];
        [properties enumerateKeysAndObjectsUsingBlock:^(id key, id obj, BOOL *stop) {
            dic[key] = [self serialize:[data valueForKey:key]];
        }];

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

+(NSDictionary *)propertiesWithEncodedTypes:(Class)class
{

    // DO NOT use a static variable to cache this, it will cause problem with subclasses of classes that are subclasses of SQLitePersistentObject

    // Recurse up the classes, but stop at NSObject. Each class only reports its own properties, not those inherited from its superclass
    NSMutableDictionary *theProps;

    if (class != [NSObject class])
    	theProps = (NSMutableDictionary *)[self propertiesWithEncodedTypes:[class superclass]];
    else
    	return [NSMutableDictionary dictionary];

    unsigned int outCount;


    objc_property_t *propList = class_copyPropertyList(class, &outCount);
    int i;

    // Loop through properties and add declarations for the create
    for (i=0; i < outCount; i++)
    {
    	objc_property_t * oneProp = propList + i;
    	NSString *propName = [NSString stringWithUTF8String:property_getName(*oneProp)];
    	NSString *attrs = [NSString stringWithUTF8String: property_getAttributes(*oneProp)];
    	NSArray *attrParts = [attrs componentsSeparatedByString:@","];
    	if (propName)
    	{
    		if ([attrParts count] > 0)
    		{
    			NSString *propType = [[attrParts objectAtIndex:0] substringFromIndex:1];
    			[theProps setObject:propType forKey:propName];
    		}
    	}
    }

    free(propList);
    
    return theProps;	
}

@end
