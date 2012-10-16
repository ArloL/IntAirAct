/** Representation of a remote procedure call. */
@interface IAAction : NSObject

/** Name of the action to call. */
@property (strong) NSString * action;

/** The parameters of the remote procedure call. */
@property (strong) NSArray * parameters;

@end
