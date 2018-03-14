#import <Foundation/Foundation.h>
#import "CommentsViewController.h"
@class WPTableViewHandler;


/**
 Fakes tableViewHandler as a protected property. Only classes importing this header will have access to it
 */
@interface CommentsViewController (Network)
@property (nonatomic, strong) WPTableViewHandler *tableViewHandler;

- (void)refreshAndSyncIfNeeded;

@end
