#import <Foundation/Foundation.h>

@interface RemotePostTag : NSObject

@property (nonatomic, strong) NSNumber *tagID;
@property (nonatomic, strong) NSString *name;
@property (nonatomic, strong) NSString *slug;
@property (nonatomic, strong) NSString *tagDescription;
@property (nonatomic, strong) NSNumber *postCount;

@end
