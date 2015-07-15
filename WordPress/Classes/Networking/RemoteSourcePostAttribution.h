#import <UIKit/UIKit.h>

@interface RemoteSourcePostAttribution : NSObject

@property (nonatomic, strong) NSString *permalink;
@property (nonatomic, strong) NSString *authorName;
@property (nonatomic, strong) NSString *authorURL;
@property (nonatomic, strong) NSString *blogName;
@property (nonatomic, strong) NSString *blogURL;
@property (nonatomic, strong) NSString *avatarURL;
@property (nonatomic, strong) NSNumber *blogID;
@property (nonatomic, strong) NSNumber *postID;
@property (nonatomic, strong) NSNumber *likeCount;
@property (nonatomic, strong) NSNumber *commentCount;
@property (nonatomic, strong) NSArray *taxonomies;

@end
