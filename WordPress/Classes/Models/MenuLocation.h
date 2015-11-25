#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>

@class Menu, Blog;

NS_ASSUME_NONNULL_BEGIN

@interface MenuLocation : NSManagedObject

@property (nullable, nonatomic, retain) NSString *defaultState;
@property (nullable, nonatomic, retain) NSString *details;
@property (nullable, nonatomic, retain) NSString *name;
@property (nullable, nonatomic, retain) Blog *blog;
@property (nullable, nonatomic, retain) Menu *menu;

+ (NSString *)entityName;

@end

NS_ASSUME_NONNULL_END