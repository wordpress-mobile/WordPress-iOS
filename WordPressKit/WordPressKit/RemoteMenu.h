#import <Foundation/Foundation.h>

@class RemoteMenuItem;
@class RemoteMenuLocation;

@interface RemoteMenu : NSObject

@property (nullable, nonatomic, copy) NSNumber *menuID;
@property (nullable, nonatomic, copy) NSString *details;
@property (nullable, nonatomic, copy) NSString *name;
@property (nullable, nonatomic, strong) NSArray<RemoteMenuItem *> *items;
@property (nullable, nonatomic, strong) NSArray<NSString *> *locationNames;

@end
