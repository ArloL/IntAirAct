#import "IADeSerialization.h"

@class IAIntAirAct;

/**
 Represents a response.
 */
@interface IAResponse : IADeSerialization

/**
 The status code of the response.

 This is typically a HTTP status code, e.g. @404.
 
 The default value is @200.
 */
@property (nonatomic, strong) NSNumber * statusCode;

/**
 The metadata of the response.
 */
@property (nonatomic, strong) NSMutableDictionary * metadata;

@end
