#import <Foundation/Foundation.h>

@interface StatsLatestPostSummary : NSObject

@property (nonatomic, strong) NSNumber *postID;
@property (nonatomic, copy)   NSString *postTitle;
@property (nonatomic, copy)   NSString *postAge;
@property (nonatomic, strong) NSURL *postURL;

@property (nonatomic, strong) NSString *views;
@property (nonatomic, strong) NSString *likes;
@property (nonatomic, strong) NSString *comments;

@property (nonatomic, strong) NSNumber *viewsValue;
@property (nonatomic, strong) NSNumber *likesValue;
@property (nonatomic, strong) NSNumber *commentsValue;


@end
