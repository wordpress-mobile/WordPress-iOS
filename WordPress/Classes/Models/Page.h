#import <Foundation/Foundation.h>
#import "AbstractPost.h"

@interface Page : AbstractPost

@property (nonatomic, strong) NSNumber * parentID;
@property (nonatomic, strong, readonly) NSString *sectionIdentifier;

@end
