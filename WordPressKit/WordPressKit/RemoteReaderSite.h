#import <Foundation/Foundation.h>

@interface RemoteReaderSite : NSObject

@property (nonatomic, strong) NSNumber *recordID;
@property (nonatomic, strong) NSNumber *siteID;
@property (nonatomic, strong) NSNumber *feedID;
@property (nonatomic, strong) NSString *name;
@property (nonatomic, strong) NSString *path; // URL
@property (nonatomic, strong) NSString *icon; // Sites only
@property (nonatomic) BOOL isSubscribed;

@end
