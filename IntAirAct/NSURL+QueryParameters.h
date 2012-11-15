@interface NSURL (QueryParameters)

- (NSURL *)URLByAppendingQueryString:(NSString *)queryString;
- (NSURL *)URLByAppendingQueryParameters:(NSDictionary *)parameters;

@end
