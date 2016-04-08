#import <Foundation/Foundation.h>

@class RemoteMenuItem;
@class RemoteMenuLocation;

@interface RemoteMenu : NSObject

@property (nonatomic, copy) NSString *menuId;
@property (nonatomic, copy) NSString *details;
@property (nonatomic, copy) NSString *name;
@property (nonatomic, strong) NSArray<RemoteMenuItem *> *items;
@property (nonatomic, strong) NSArray<NSString *> *locationNames;

@end
