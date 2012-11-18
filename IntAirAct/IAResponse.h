#import "IADeSerialization.h"

@class IAIntAirAct;

@interface IAResponse : IADeSerialization

#define OK @200
#define CREATED @201

#define ERROR @400
#define NOT_FOUND @404

@property (nonatomic, strong) NSNumber * statusCode;
@property (nonatomic, strong) NSMutableDictionary * metadata;

@end
