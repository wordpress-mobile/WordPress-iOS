#import <Foundation/Foundation.h>

@interface RemoteReaderTopic : NSObject

@property (nonatomic) BOOL isMenuItem;
@property (nonatomic) BOOL isRecommended;
@property (nonatomic) BOOL isSubscribed;
@property (nonatomic, strong) NSString *path;
@property (nonatomic, strong) NSString *slug;
@property (nonatomic, strong) NSString *title;
@property (nonatomic, strong) NSString *topicDescription;
@property (nonatomic, strong) NSNumber *topicID;
@property (nonatomic, strong) NSString *type;

@end
