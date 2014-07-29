#import <CoreData/CoreData.h>

@class WPAccount;

@interface ReaderSite : NSManagedObject

@property (nonatomic, strong) WPAccount *account;
@property (nonatomic, strong) NSNumber *recordID;
@property (nonatomic, strong) NSNumber *siteID;
@property (nonatomic, strong) NSNumber *feedID;
@property (nonatomic, strong) NSString *name;
@property (nonatomic, strong) NSString *path; // URL
@property (nonatomic, strong) NSString *icon; // Sites only
@property (nonatomic) BOOL isSubscribed;

@end
