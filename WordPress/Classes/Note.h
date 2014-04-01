#import <Foundation/Foundation.h>
#import "WPAccount.h"
#import "WPContentViewProvider.h"

@interface Note : NSManagedObject<WPContentViewProvider>

@property (nonatomic, retain) NSNumber *timestamp;
@property (nonatomic, retain) NSString *type;
@property (nonatomic, retain) NSString *subject;
@property (nonatomic, retain) NSData *payload;
@property (nonatomic, retain) NSNumber *unread;
@property (nonatomic, retain) NSString *icon;
@property (nonatomic, retain) NSString *noteID;
@property (nonatomic, retain) WPAccount *account;
@property (nonatomic, strong, readonly) NSString *commentText;
@property (nonatomic, strong, readonly) NSDictionary *noteData;

- (BOOL)isComment;
- (BOOL)isLike;
- (BOOL)isFollow;
- (BOOL)isRead;
- (BOOL)isUnread;
- (BOOL)statsEvent;

- (void)syncAttributes:(NSDictionary *)data;

@end
