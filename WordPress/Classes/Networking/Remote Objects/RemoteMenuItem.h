#import <Foundation/Foundation.h>

@interface RemoteMenuItem : NSObject

@property (nonatomic, copy) NSString *itemId;
@property (nonatomic, copy) NSString *contentId;
@property (nonatomic, copy) NSString *details;
@property (nonatomic, copy) NSString *linkTarget;
@property (nonatomic, copy) NSString *linkTitle;
@property (nonatomic, copy) NSString *name;
@property (nonatomic, copy) NSString *type;
@property (nonatomic, copy) NSString *typeFamily;
@property (nonatomic, copy) NSString *typeLabel;
@property (nonatomic, copy) NSString *urlStr;

@property (nonatomic, strong) NSArray<RemoteMenuItem *> *children;
@property (nonatomic, weak) RemoteMenuItem *parentItem;

@end
