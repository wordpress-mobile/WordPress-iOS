#import <Foundation/Foundation.h>

@interface RemoteMenuItem : NSObject

@property (nullable, nonatomic, copy) NSNumber *itemID;
@property (nullable, nonatomic, copy) NSNumber *contentID;
@property (nullable, nonatomic, copy) NSString *details;
@property (nullable, nonatomic, copy) NSString *linkTarget;
@property (nullable, nonatomic, copy) NSString *linkTitle;
@property (nullable, nonatomic, copy) NSString *name;
@property (nullable, nonatomic, copy) NSString *type;
@property (nullable, nonatomic, copy) NSString *typeFamily;
@property (nullable, nonatomic, copy) NSString *typeLabel;
@property (nullable, nonatomic, copy) NSString *urlStr;
@property (nullable, nonatomic, copy) NSArray<NSString *> *classes;

@property (nullable, nonatomic, strong) NSArray<RemoteMenuItem *> *children;
@property (nullable, nonatomic, weak) RemoteMenuItem *parentItem;

@end
