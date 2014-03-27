#import "IADeSerialization.h"

@class IARoute;
@class IADevice;

/**
 A request is sent or received.
 */
@interface IARequest : IADeSerialization

/**
 Construct a new request with only a route.

 @param route The route of the request.

 @return Returns the new request.
 */
+(IARequest*)requestWithRoute:(IARoute*)route;

/**
 Construct a new request without parameters or metadata.

 @param route The route of the request.
 @param origin The origin device of the request.
 @param body The body of the request.

 @return Returns the new request.
 */
+(IARequest*)requestWithRoute:(IARoute*)route origin:(IADevice*)origin body:(id)data;

/**
 Construct a new request.

 @param route The route of the request.
 @param metadata The metadata of the request.
 @param parameters The parameters of the request.
 @param origin The origin device of the request.
 @param body The body of the request.

 @return Returns the new request.
 */
+(IARequest*)requestWithRoute:(IARoute*)route metadata:(NSMutableDictionary*)metadata parameters:(NSMutableDictionary*)parameters origin:(IADevice*)origin body:(NSData*)body;

/**
 Initialize a new request.

 @param route The route of the request.
 @param metadata The metadata of the request.
 @param parameters The parameters of the request.
 @param origin The origin device of the request.
 @param body The body of the request.

 @return Returns the new request.
 */
-(id)initWithRoute:(IARoute*)route metadata:(NSMutableDictionary*)metadata parameters:(NSMutableDictionary*)parameters origin:(IADevice*)origin body:(NSData*)body;

/**
 The route of the request.
 
 This is where the request was received or where it will be sent to.
 */
@property (nonatomic, strong) IARoute * route;

/**
 The metadata of the request.
 */
@property (nonatomic, strong) NSMutableDictionary * metadata;

/**
 The parameters of the request.
 
 These set the {parameters} of the route's resource.
 */
@property (nonatomic, strong) NSMutableDictionary * parameters;

/**
 The device where the request came from.
 */
@property (nonatomic, strong) IADevice * origin;

@end
