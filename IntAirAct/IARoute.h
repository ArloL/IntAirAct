@interface IARoute : NSObject

// Short-hand constructors for custom routes.
+(IARoute*)putRoute:(NSString*)resource;
+(IARoute*)postRoute:(NSString*)resource;
+(IARoute*)getRoute:(NSString*)resource;
+(IARoute*)deleteRoute:(NSString*)resource;

+(IARoute*)routeWithAction:(NSString*)action resource:(NSString*)resource;

// Constructor
-(id)initWithAction:(NSString *)action resource:(NSString*)resource;

@property (strong, readonly) NSString * action;
@property (strong, readonly) NSString * resource;

@end
