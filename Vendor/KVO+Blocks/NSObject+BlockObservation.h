//
//  NSObject+BlockObservation.h
//  Version 1.0
//
//  Andy Matuschak
//  andy@andymatuschak.org
//  Public domain because I love you. Let me know how you use it.
//

typedef NSString AMBlockToken;
typedef void (^AMBlockTask)(id obj, NSDictionary *change);

@interface NSObject (AMBlockObservation)
- (AMBlockToken *)addObserverForKeyPath:(NSString *)keyPath task:(AMBlockTask)task;
- (AMBlockToken *)addObserverForKeyPath:(NSString *)keyPath onQueue:(NSOperationQueue *)queue task:(AMBlockTask)task;
- (void)removeObserverWithBlockToken:(AMBlockToken *)token;
@end
