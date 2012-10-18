@interface SDServiceDiscovery : NSObject<NSNetServiceBrowserDelegate, NSNetServiceDelegate>

@property (strong) NSString * type;
@property (strong) NSString * domain;
@property BOOL autostart;

-(void)startSearching;
-(void)stopSearching;

-(void)startSearchingForType:(NSString*)type inDomain:(NSString*)domain;
-(void)stopSearchingForType:(NSString*)type inDomain:(NSString*)domain;

@end
