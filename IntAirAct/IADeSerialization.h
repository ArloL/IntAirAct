#import <Foundation/Foundation.h>

@interface IADeSerialization : NSObject

@property (nonatomic, strong) NSData * body;
@property (nonatomic, strong) NSString * contentType;

-(id)initWithBody:(NSData*)body;

-(void)setBodyWith:(id)data;
-(void)setBodyWithString:(NSString *)string;
-(void)setBodyWithNumber:(NSNumber *)number;

-(id)bodyAs:(Class)class;

/** @return The body of the request as a string. */
-(NSString *)bodyAsString;
-(NSNumber *)bodyAsNumber;

@end
