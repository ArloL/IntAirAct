@interface IARoute : NSObject

// Short-hand constructors for custom routes.
+(IARoute*)put:(NSString*)resource;
+(IARoute*)post:(NSString*)resource;
+(IARoute*)get:(NSString*)resource;
+(IARoute*)delete:(NSString*)resource;

+(IARoute*)routeWithAction:(NSString*)action resource:(NSString*)resource;

// Constructor
-(id)initWithAction:(NSString *)action resource:(NSString*)resource;

@property (strong, readonly) NSString * action;
@property (strong, readonly) NSString * resource;

@end
