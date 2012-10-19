@interface SDServiceDiscovery : NSObject<NSNetServiceBrowserDelegate, NSNetServiceDelegate>

-(id)initWithQueue:(dispatch_queue_t)queue;

-(void)stop;
-(void)stopSearching;
-(void)stopPublishing;

-(void)searchForServicesOfType:(NSString*)type;

-(void)searchForServicesOfType:(NSString*)type
                      inDomain:(NSString*)domain;

-(void)stopSearchingForServicesOfType:(NSString*)type;

-(void)stopSearchingForServicesOfType:(NSString*)type
                             inDomain:(NSString*)domain;

-(void)publishServiceOfType:(NSString*)type
                     onPort:(int)port;

-(void)publishServiceOfType:(NSString*)type
                     onPort:(int)port
                   withName:(NSString*)name;

-(void)publishServiceOfType:(NSString*)type
                     onPort:(int)port
                   withName:(NSString*)name
                   inDomain:(NSString*)domain;

-(void)publishServiceOfType:(NSString*)type
                     onPort:(int)port
                   withName:(NSString*)name
                   inDomain:(NSString*)domain
                  TXTRecord:(NSDictionary*)TXTRecord;

-(void)stopPublishingServiceOfType:(NSString*)type
                            onPort:(int)port;

-(void)stopPublishingServiceOfType:(NSString*)type
                            onPort:(int)port
                          inDomain:(NSString*)domain;

@end
