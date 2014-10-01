#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>

@class WPAccount;

@interface ReaderSite : NSManagedObject

@property (nonatomic, strong) NSNumber *recordID;
@property (nonatomic, strong) NSNumber *siteID;
@property (nonatomic, strong) NSNumber *feedID;
@property (nonatomic, strong) NSString *name;
@property (nonatomic, strong) NSString *path;
@property (nonatomic, strong) NSString *icon;
@property (nonatomic, assign) BOOL isSubscribed;
@property (nonatomic, strong) WPAccount *account;

- (BOOL)isFeed;
- (NSString *)nameForDisplay;
- (NSString *)pathForDisplay;

@end
