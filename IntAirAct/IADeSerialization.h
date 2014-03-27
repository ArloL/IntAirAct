/**
 Base class for IARequest and IAResponse that does all the heavy lifting
 of de-/serialization.
 */
@interface IADeSerialization : NSObject

/**
 The body.
 */
@property (nonatomic, strong) NSData * body;

/**
 The content type.
 */
@property (nonatomic, strong) NSString * contentType;

/**
 Initialize a new IADeSerialization with the specified body.

 @param body The body.
 
 @return The new IADeSerialization.
 */
-(id)initWithBody:(NSData*)body;

/**
 Set the body with a generic object.

 @param data The object.
 */
-(void)setBodyWith:(id)data;

/**
 Set the body with the specified string.

 @param string The string.
 */
-(void)setBodyWithString:(NSString *)string;

/**
 Set the body with the specified number.
 
 @param number The number.
 */
-(void)setBodyWithNumber:(NSNumber *)number;

/**
 @return The body as the specified class.
 */
-(id)bodyAs:(Class)class;

/**
 @return The body as a string.
 */
-(NSString *)bodyAsString;

/**
 @return The body as a number.
 */
-(NSNumber *)bodyAsNumber;

@end
