#import <Foundation/Foundation.h>

@class WPAccount;

@interface ReaderTopic : NSManagedObject

@property (nonatomic, strong) WPAccount *account;
@property (nonatomic) BOOL isMenuItem;
@property (nonatomic) BOOL isRecommended;
@property (nonatomic) BOOL isSubscribed;
@property (nonatomic, strong) NSDate *lastSynced;
@property (nonatomic, strong) NSString *path;
@property (nonatomic, strong) NSArray *posts;
@property (nonatomic, strong) NSString *slug;
@property (nonatomic, strong) NSString *title;
@property (nonatomic, strong) NSString *topicDescription;
@property (nonatomic, strong) NSNumber *topicID;
@property (nonatomic, strong) NSString *type;

@end
