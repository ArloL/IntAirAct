@class RKObjectLoader;
@class RKObjectManager;
@class RKObjectMappingProvider;
@class RKObjectMappingResult;
@class RKObjectRouter;
@class RKObjectSerializer;
@class RoutingHTTPServer;

@class IAAction;
@class IADevice;

@interface IAInteract : NSObject <NSNetServiceBrowserDelegate, NSNetServiceDelegate>

@property (nonatomic, strong) RoutingHTTPServer * httpServer;
@property (nonatomic, strong) RKObjectMappingProvider * objectMappingProvider;
@property (nonatomic, strong) RKObjectRouter * router;

/**
 * Attempts to start the server.
 * 
 * If an error occurs, this method returns NO and sets the errPtr (if given).
 * Otherwise returns YES on success.
 * 
 * Code Example:
 * 
 * NSError *err = nil;
 * if (![interact start:&err])
 * {
 *     NSLog(@"Error starting interact: %@", err);
 * }
 **/
-(BOOL)start:(NSError **)errPtr;

-(void)stop;

-(BOOL)isRunning;

-(void)setServer:(BOOL)server;
-(BOOL)server;

-(void)setClient:(BOOL)client;
-(BOOL)client;

-(void)setDefaultMimeType:(NSString *)defaultMimeType;
-(NSString *)defaultMimeType;

-(void)addMappingForClass:(Class)className withKeypath:(NSString *)keyPath withAttributes:(NSString *)attributeKeyPath, ...  NS_REQUIRES_NIL_TERMINATION;

-(RKObjectManager *)objectManagerForDevice:(IADevice *)device;
-(NSString *)resourcePathFor:(NSObject *)resource forObjectManager:(RKObjectManager *)manager;
-(RKObjectSerializer *)serializerForObject:(id)object;
-(NSArray *)devices;
-(RKObjectMappingResult *)deserializeObject:(NSData *)data;
-(RKObjectMappingResult *)deserializeDictionary:(NSDictionary *)dictionary;
-(IADevice *)ownDevice;
-(void)callAction:(IAAction *)action onDevice:(IADevice *)device;
-(void)loadObjectsAtResourcePath:(NSString*)resourcePath fromDevice:(IADevice *)device handler:(void (^)(RKObjectLoader *loader, NSError *error))handler;

@end
