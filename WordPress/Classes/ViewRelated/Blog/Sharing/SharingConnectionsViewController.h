#import <UIKit/UIKit.h>

@class Blog;
@class PublicizeService;

/**
 *	@brief	Controller to display Calypso sharing options
 */
@interface SharingConnectionsViewController : UITableViewController

/**
 *	@brief	Convenience initializer
 *
 *  @param  blog    the blog from where to read the information from
 *
 *  @return New instance of SharingViewController
 */
- (instancetype)initWithBlog:(Blog *)blog publicizeService:(PublicizeService *)publicizeService;

@end
