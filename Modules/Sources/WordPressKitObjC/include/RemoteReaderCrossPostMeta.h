#import <Foundation/Foundation.h>

@interface RemoteReaderCrossPostMeta : NSObject

@property (nonatomic, strong, nullable) NSNumber *postID;
@property (nonatomic, strong, nullable) NSNumber *siteID;
@property (nonatomic, strong, nullable) NSString *siteURL;
@property (nonatomic, strong, nullable) NSString *postURL;
@property (nonatomic, strong, nullable) NSString *commentURL;

@end
