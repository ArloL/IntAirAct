// Add support for subscripting to the iOS 5 SDK.
#if __IPHONE_OS_VERSION_MAX_ALLOWED < 60000
@interface NSObject (SubscriptingSupport)

- (id)objectAtIndexedSubscript:(NSUInteger)idx;
- (void)setObject:(id)obj atIndexedSubscript:(NSUInteger)idx;
- (void)setObject:(id)obj forKeyedSubscript:(id <NSCopying>)key;
- (id)objectForKeyedSubscript:(id)key;

@end
#endif