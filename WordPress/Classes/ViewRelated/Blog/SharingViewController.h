#import <UIKit/UIKit.h>

@protocol SharingViewControllerDelegate

- (void)didChangePublicizeServices;

@end

@class Blog;

/**
 *	@brief	Controller to display Calypso sharing options
 */
@interface SharingViewController : UITableViewController

/**
 *	@brief	Convenience initializer
 *
 *  @param  blog    the blog from where to read the information from
 *
 *  @return New instance of SharingViewController
 */
- (instancetype)initWithBlog:(Blog *)blog delegate:(id)delegate;

@end
