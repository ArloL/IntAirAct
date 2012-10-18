@class IARoute;
@class IARequest;
@class IAResponse;

typedef void (^IARequestHandler)(IARequest *request, IAResponse *response);

@protocol IARouter <NSObject>

// returns NO when the route already exists
-(BOOL)route:(IARoute*)route withHandler:(IARequestHandler)handler;

@end
