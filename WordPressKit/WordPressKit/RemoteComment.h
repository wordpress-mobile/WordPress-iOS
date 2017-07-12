#import <Foundation/Foundation.h>

@interface RemoteComment : NSObject
@property (nonatomic, strong) NSNumber *commentID;
@property (nonatomic, strong) NSString *author;
@property (nonatomic, strong) NSString *authorEmail;
@property (nonatomic, strong) NSString *authorUrl;
@property (nonatomic, strong) NSString *authorAvatarURL;
@property (nonatomic, strong) NSString *content;
@property (nonatomic, strong) NSDate *date;
@property (nonatomic, strong) NSString *link;
@property (nonatomic, strong) NSNumber *parentID;
@property (nonatomic, strong) NSNumber *postID;
@property (nonatomic, strong) NSString *postTitle;
@property (nonatomic, strong) NSString *status;
@property (nonatomic, strong) NSString *type;
@property (nonatomic) BOOL isLiked;
@property (nonatomic, strong) NSNumber *likeCount;
@end
