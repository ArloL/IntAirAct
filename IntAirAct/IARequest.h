#import <Foundation/Foundation.h>

@class IARoute;
@class IADevice;

@interface IARequest : NSObject

-(id)initWithRoute:(IARoute*)route metadata:(NSDictionary*)metadata parameters:(NSDictionary*)parameters origin:(IADevice*)origin body:(NSData*)body;

@property (strong, readonly) IARoute * route;
@property (strong, readonly) NSDictionary * metadata;
@property (strong, readonly) NSDictionary * parameters;
@property (strong, readonly) IADevice * origin;
@property (strong, readonly) NSData * body;

// accessor methods for metadata and parameters
- (NSString *)metadata:(NSString *)field;
- (id)parameter:(NSString *)name;

@end
