#import <Foundation/Foundation.h>
#import "AbstractPost.h"

NS_ASSUME_NONNULL_BEGIN

@interface Page : AbstractPost

@property (nonatomic, strong, nullable) NSNumber * parentID;
- (NSString *)sectionIdentifier;

@end

NS_ASSUME_NONNULL_END
