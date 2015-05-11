#import <Foundation/Foundation.h>

@interface RemotePostStatus : NSObject

@property (nonatomic, strong) NSString * label;
@property (nonatomic, strong) NSString * name;
@property (nonatomic, strong) NSNumber * isProtected;
@property (nonatomic, strong) NSNumber * isPrivate;
@property (nonatomic, strong) NSNumber * isPublic;

@end
