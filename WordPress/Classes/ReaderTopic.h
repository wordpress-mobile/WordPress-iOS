#import <Foundation/Foundation.h>

extern NSString *const ReaderTopicTypeList;
extern NSString *const ReaderTopicTypeTag;

@interface ReaderTopic : NSManagedObject

@property (nonatomic) BOOL isRecommended;
@property (nonatomic) BOOL isSubscribed;
@property (nonatomic, strong) NSDate *lastSynced;
@property (nonatomic, strong) NSString *path;
@property (nonatomic, strong) NSArray *posts;
@property (nonatomic, strong) NSString *title;
@property (nonatomic, strong) NSNumber *topicID;
@property (nonatomic, strong) NSString *type;

@end
