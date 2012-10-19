@interface SDServiceDiscovery : NSObject<NSNetServiceBrowserDelegate, NSNetServiceDelegate>

-(void)stop;
-(void)stopSearching;
-(void)stopPublishing;

-(BOOL)searchForServicesOfType:(NSString*)type;

-(BOOL)searchForServicesOfType:(NSString*)type
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
                  txtRecord:(NSDictionary*)txtRecord;

-(void)stopPublishingServiceOfType:(NSString*)type
                            onPort:(int)port;

-(void)stopPublishingServiceOfType:(NSString*)type
                            onPort:(int)port
                          inDomain:(NSString*)domain;

@end
