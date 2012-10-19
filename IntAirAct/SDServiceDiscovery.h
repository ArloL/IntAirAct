@interface SDServiceDiscovery : NSObject<NSNetServiceBrowserDelegate, NSNetServiceDelegate>

@property (strong) NSString * type;
@property (strong) NSString * domain;
@property (strong) NSString * name;
@property NSInteger port;
@property BOOL autostart;

-(void)startSearching;
-(void)stopSearching;

-(void)startSearchingForType:(NSString*)type
                    inDomain:(NSString*)domain;

-(void)stopSearchingForType:(NSString*)type
                   inDomain:(NSString*)domain;

-(void)stopAllSearches;

-(void)publishServiceWithName:(NSString*)name
                         port:(int)port
                       ofType:(NSString*)type
                     inDomain:(NSString*)domain;

-(void)stopPublishingServiceWithName:(NSString*)name
                                port:(int)port
                              ofType:(NSString*)type
                            inDomain:(NSString*)domain;

-(void)stopPublishingServices;

@end
