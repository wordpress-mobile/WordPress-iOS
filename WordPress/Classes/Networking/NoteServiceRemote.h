#import <Foundation/Foundation.h>

@class WordPressComApi;

@interface NoteServiceRemote : NSObject

- (id)initWithRemoteApi:(WordPressComApi *)api;

- (void)fetchNotificationsSince:(NSNumber *)timestamp success:(void (^)(NSArray *notes))success failure:(void (^)(NSError *error))failure;

- (void)fetchNotificationsBefore:(NSNumber *)timestamp success:(void (^)(NSArray *notes))success failure:(void (^)(NSError *error))failure;

- (void)refreshNoteId:(NSString *)noteId success:(void (^)(NSArray *notes))success failure:(void (^)(NSError *error))failure;

- (void)markNoteIdAsRead:(NSString *)noteId success:(void (^)())success failure:(void (^)(NSError *error))failure;

- (void)refreshNotificationIds:(NSArray *)noteIds success:(void (^)())success failure:(void (^)(NSError *error))failure;

@end
