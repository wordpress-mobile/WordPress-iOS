#import "NoteServiceRemote.h"
#import "WordPressComApi.h"

@interface NoteServiceRemote ()

@property (nonatomic, strong) WordPressComApi *api;

@end

@implementation NoteServiceRemote

- (id)initWithRemoteApi:(WordPressComApi *)api
{
    self = [super init];
    if (self) {
        _api = api;
    }
    
    return self;
}

- (void)fetchNotificationsSince:(NSNumber *)timestamp success:(void (^)(NSArray *notes))success failure:(void (^)(NSError *error))failure
{
    [self.api fetchNotificationsSince:timestamp success:^(NSArray *notes) {
        if (success) {
            success(notes);
        }
    } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
        if (failure) {
            failure(error);
        }
    }];
}

- (void)fetchNotificationsBefore:(NSNumber *)timestamp success:(void (^)(NSArray *notes))success failure:(void (^)(NSError *error))failure
{
    [self.api fetchNotificationsBefore:timestamp success:^(NSArray *notes) {
        if (success) {
            success(notes);
        }
    } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
        if (failure) {
            failure(error);
        }
    }];
}

- (void)refreshNoteId:(NSString *)noteId success:(void (^)(NSArray *notes))success failure:(void (^)(NSError *))failure
{
    [self.api refreshNotifications:@[noteId]
                            fields:nil
                           success:^(NSArray *updatedNotes) {
                               if (success) {
                                   success(updatedNotes);
                               }
                           }
                           failure:^(AFHTTPRequestOperation *operation, NSError *error) {
                               if (failure) {
                                   failure(error);
                               }
                           }
     ];
}

- (void)markNoteIdAsRead:(NSString *)noteId success:(void (^)())success failure:(void (^)(NSError *))failure
{
    [self.api markNoteAsRead:noteId
                     success:^(AFHTTPRequestOperation *operation, id responseObject) {
                         if (success) {
                             success();
                         }
                     }
                     failure:^(AFHTTPRequestOperation *operation, NSError *error) {
                         if (failure) {
                             failure(error);
                         }
                     }];
}

- (void)refreshNotificationIds:(NSArray *)noteIds success:(void (^)())success failure:(void (^)(NSError *error))failure
{
    [self.api refreshNotifications:noteIds
                            fields:@"id,unread"
                           success:success
                           failure:^(AFHTTPRequestOperation *operation, NSError *error) {
                               if (failure) {
                                   failure(error);
                               }
                           }
     ];
}


@end
