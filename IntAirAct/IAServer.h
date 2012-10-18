@class IARoute;
@class IARequest;
@class IAResponse;

typedef void (^IARequestHandler)(IARequest *request, IAResponse *response);

@protocol IAServer <NSObject>

/** The port on which to listen on. Default is 0. This means the system will find a free port. */
@property (nonatomic) NSInteger port;

// returns NO when the route already exists
-(BOOL)route:(IARoute*)route withHandler:(IARequestHandler)handler;

-(BOOL)start:(NSError **)errPtr;

-(void)stop;

@end
