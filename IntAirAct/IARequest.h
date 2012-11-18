#import "IADeSerialization.h"

@class IARoute;
@class IADevice;

@interface IARequest : IADeSerialization

+(IARequest*)requestWithRoute:(IARoute*)route origin:(IADevice*)origin body:(id)data;

+(IARequest*)requestWithRoute:(IARoute*)route metadata:(NSMutableDictionary*)metadata parameters:(NSMutableDictionary*)parameters origin:(IADevice*)origin body:(NSData*)body;

-(id)initWithRoute:(IARoute*)route metadata:(NSMutableDictionary*)metadata parameters:(NSMutableDictionary*)parameters origin:(IADevice*)origin body:(NSData*)body;

@property (nonatomic, strong) IARoute * route;
@property (nonatomic, strong) NSMutableDictionary * metadata;
@property (nonatomic, strong) NSMutableDictionary * parameters;
@property (nonatomic, strong) IADevice * origin;

@end
