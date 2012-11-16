#import "IADeSerialization.h"

@class IARoute;
@class IADevice;

@interface IARequest : IADeSerialization

+(IARequest*)requestWithRoute:(IARoute*)route metadata:(NSDictionary*)metadata parameters:(NSDictionary*)parameters origin:(IADevice*)origin body:(NSData*)body;

-(id)initWithRoute:(IARoute*)route metadata:(NSDictionary*)metadata parameters:(NSDictionary*)parameters origin:(IADevice*)origin body:(NSData*)body;

@property (strong, readonly) IARoute * route;
@property (strong, readonly) NSDictionary * metadata;
@property (strong, readonly) NSDictionary * parameters;
@property (strong, readonly) IADevice * origin;

@end
