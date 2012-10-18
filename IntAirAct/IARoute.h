@interface IARoute : NSObject

// These are the pre-defined routes included with IntAirAct.
+(IARoute*)imageRoute;
+(IARoute*)textRoute;
+(IARoute*)videoRoute;

// Short-hand constructors for custom routes.
+(IARoute*)putRoute:(NSString*)resource;
+(IARoute*)postRoute:(NSString*)resource;
+(IARoute*)getRoute:(NSString*)resource;
+(IARoute*)deleteRoute:(NSString*)resource;

+(IARoute*)route:(NSString*)action resource:(NSString*)resource;

// Constructor
-(id)initWithAction:(NSString *)action resource:(NSString*)resource;

@property (readonly) NSString * action;
@property (readonly) NSString * resource;

@end
