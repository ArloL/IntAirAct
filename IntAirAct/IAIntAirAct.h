@class RKObjectLoader;
@class RKObjectManager;
@class RKObjectMappingProvider;
@class RKObjectMappingResult;
@class RKObjectRouter;
@class RKObjectSerializer;
@class RoutingHTTPServer;

@class IAAction;
@class IADevice;

@interface IAIntAirAct : NSObject <NSNetServiceBrowserDelegate, NSNetServiceDelegate>

/** Specifies whether IntAirAct is configured as a client or not.
 
 Defaults to `application/json`.
 
 When changing this value be sure that RestKit has a parser and a serializer (!) available for that MIME type. The included `RKXMLParserLibXML` currently does not support serialization.
 */
@property BOOL client;

/** Specifies the default MIME Type used when de-/serializing objects.
 */
@property NSString * defaultMimeType;

/** Returns a list of all the currently available devices.
 */
@property (readonly) NSArray * devices;

/** The embedded HTTP server.
 
 It's available for publishing an endpoint like this:
 
    [http handleMethod:@"GET" withPath:@"/hello" block:^(RouteRequest *request, RouteResponse *response) {
        [response setHeader:@"Content-Type" value:@"text/plain"];
        [response respondWithString:@"Hello!"];
    }];
 */
@property (nonatomic, strong, readonly) RoutingHTTPServer * httpServer;

/** Returns `YES` if IntAirAct is running, `NO` otherwise.
 */
@property (readonly) BOOL isRunning;

/** IntAirAct's RKObjectMappingProvider. This is used to add and retrieve object mappings.
 
 A usage example:
 
    RKObjectMapping * mapping = [RKObjectMapping mappingForClass:[Contact class]];
    [mapping mapAttributesFromSet:@"firstName", @"lastName", nil];
    [intairact.objectMappingProvider setMapping:mapping forKeyPath:@"contacts"];
 */
@property (nonatomic, strong, readonly) RKObjectMappingProvider * objectMappingProvider;

/** Returns the current device if it has been found yet, `nil` otherwise.
 */
@property (readonly) IADevice * ownDevice;

/** IntAirAct's RKObjectRouter. This is used to setup default route mappings for objects.
 
 Use this to setup default routes for serializable Objects like this:
 
    [intairact.router routeClass:[Contact class] toResourcePath:@"/contacts/:identifier"];
 
 This automatically maps all GET, POST, PUT and DELETE calls to /contacts/:identifier.
 */
@property (nonatomic, strong, readonly) RKObjectRouter * router;

/** Specifies whether IntAirAct is configured as a server or not.
 
 If set to `YES`, IntAirAct will start the embedded HTTP server. Defaults to `YES`.
 */
@property BOOL server;

/** Standard Constructor.
 
 Instantiates IntAirAct, but does not start it.
 */
-(id)init;

/** Standard Deconstructor.
 
 Stops the server, and clients, and releases any resources connected with this instance.
 */
-(void)dealloc;

/** Attempts to start IntAirAct.
 
 A usage example:
 
    NSError *err = nil;
    if (![intairact start:&er]]) {
        NSLog(@"Error starting IntAirAct: %@", err);
    }
 
 @param errPtr An optional NSError instance.
 @return Returns `YES` if successful, `NO` on failure and sets the errPtr (if given).
 
 */
-(BOOL)start:(NSError **)errPtr;

/** Stops IntAirAct.
 */
-(void)stop;

/** Adds a de- and a serialization mapping to the objectMappingProvider for the specified class.
 
 A usage example:
 
    [intairact addMappingForClass:[Contact class] withKeypath:@"contacts" withAttributes:@"firstName", @"lastName", nil];
 
 @param className The class to be de-/serialized.
 @param keyPath The keypath to use for the mapping. This has to be unique to the application.
 @param attributeKeyPath An attribute to map.
 @param ... A comma separated list of attributes to map.
 */
-(void)addMappingForClass:(Class)className withKeypath:(NSString *)keyPath withAttributes:(NSString *)attributeKeyPath, ...  NS_REQUIRES_NIL_TERMINATION;

-(RKObjectManager *)objectManagerForDevice:(IADevice *)device;
-(NSString *)resourcePathFor:(NSObject *)resource forObjectManager:(RKObjectManager *)manager;
-(RKObjectSerializer *)serializerForObject:(id)object;
-(RKObjectMappingResult *)deserializeObject:(NSData *)data;
-(void)callAction:(IAAction *)action onDevice:(IADevice *)device;
-(void)callAction:(IAAction *)action onDevice:(IADevice *)device withHandler:(void (^)(IAAction *, NSError *))handler;

@end
