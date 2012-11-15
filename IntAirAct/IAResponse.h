#import "IADeSerialization.h"

@class IAIntAirAct;

@interface IAResponse : IADeSerialization

#define OK @200
#define CREATED @201

#define ERROR @400
#define NOT_FOUND @404

@property (strong) NSNumber * statusCode;
@property (strong, readonly) NSMutableDictionary * metadata;

@end
