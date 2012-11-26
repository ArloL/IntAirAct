#import "IADeSerialization.h"

@class IAIntAirAct;

@interface IAResponse : IADeSerialization

@property (nonatomic, strong) NSNumber * statusCode;
@property (nonatomic, strong) NSMutableDictionary * metadata;

@end
