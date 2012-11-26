@class IARoute;
@class IARequest;
@class IAResponse;

typedef void (^IARequestHandler)(IARequest *request, IAResponse *response);

@protocol IAServer <NSObject>

/** The port on which to listen on. Default is 0. This means the system will find a free port. */
@property (nonatomic) NSInteger port;

// returns NO when the route already exists
-(BOOL)route:(IARoute*)route withHandler:(IARequestHandler)handler;

/** Attempts to start the server.
 
 A usage example:
 
    NSError *err = nil;
    if (![server start:&er]]) {
        NSLog(@"Error starting server: %@", err);
    }
 
 @param errPtr An optional NSError instance.
 @return Returns `YES` if successful, `NO` on failure and sets the errPtr (if given).
 */
-(BOOL)start:(NSError **)errPtr;

/** Stops the server. */
-(void)stop;

@end
