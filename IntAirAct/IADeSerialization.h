#import <Foundation/Foundation.h>

#import <UIKit/UIKit.h>

@interface IADeSerialization : NSObject

@property (nonatomic, strong) NSData * body;

-(id)initWithBody:(NSData*)body;

-(void)setBodyWith:(id)data;
-(id)bodyAs:(Class)class;

-(void)setBodyWithImage:(UIImage*)image;

/** @return The body of the request as a string. */
-(NSString *)bodyAsString;

- (void)setBodyWithString:(NSString *)string;
- (void)setBodyWithString:(NSString *)string encoding:(NSStringEncoding)encoding;
- (void)setBodyWithData:(NSData *)data;

@end
