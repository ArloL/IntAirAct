/**
 A route is the destination and origin of requests.

 An example for using a route is to trigger a UI refresh when receiving
 a request on a route with the "POST" action and the "/refresh" resource.
 */
@interface IARoute : NSObject

/**
 Construct a new route with action set to "PUT".

 @param resource The resource of the route.

 @return Returns the new route.
 */
+(IARoute*)put:(NSString*)resource;

/**
 Construct a new route with action set to "POST".

 @param resource The resource of the route.

 @return Returns the new route.
 */
+(IARoute*)post:(NSString*)resource;

/**
 Construct a new route with action set to "GET".

 @param resource The resource of the route.

 @return Returns the new route.
 */
+(IARoute*)get:(NSString*)resource;

/**
 Construct a new route with action set to "DELETE".

 @param resource The resource of the route.

 @return Returns the new route.
 */
+(IARoute*)delete:(NSString*)resource;

/**
 Construct a new route.

 @param action The action of the route.
 @param resource The resource of the route.

 @return Returns the new route.
 */
+(IARoute*)routeWithAction:(NSString*)action resource:(NSString*)resource;

/**
 Initialize a new route.

 @param action The action of the route.
 @param resource The resource of the route.

 @return Returns the new route.
 */
-(id)initWithAction:(NSString *)action resource:(NSString*)resource;

/**
 The action of the route.
 
 This is typically a HTTP verb, e.g. "PUT".
 */
@property (strong, readonly) NSString * action;

/**
 The resource on which the action is performed.
 */
@property (strong, readonly) NSString * resource;

@end
