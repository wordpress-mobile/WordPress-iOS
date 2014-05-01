#import <Foundation/Foundation.h>

@interface RemoteReaderTopic : NSObject

@property (nonatomic) BOOL isRecommended;
@property (nonatomic) BOOL isSubscribed;
@property (nonatomic, strong) NSString *path;
@property (nonatomic, strong) NSArray *posts;
@property (nonatomic, strong) NSString *title;
@property (nonatomic, strong) NSNumber *topicID;
@property (nonatomic, strong) NSString *type;

@end
