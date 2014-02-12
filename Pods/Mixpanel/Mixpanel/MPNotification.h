#import <Foundation/Foundation.h>

@interface MPNotification : NSObject

extern NSString *const MPNotificationTypeMini;
extern NSString *const MPNotificationTypeTakeover;

@property (nonatomic, readonly) NSUInteger ID;
@property (nonatomic, readonly) NSUInteger messageID;
@property (nonatomic, strong) NSString *type;
@property (nonatomic, strong) NSURL *imageURL;
@property (nonatomic, strong) NSData *image;
@property (nonatomic, strong) NSString *title;
@property (nonatomic, strong) NSString *body;
@property (nonatomic, strong) NSString *callToAction;
@property (nonatomic, strong) NSURL *callToActionURL;

+ (MPNotification *)notificationWithJSONObject:(NSDictionary *)object;

@end
