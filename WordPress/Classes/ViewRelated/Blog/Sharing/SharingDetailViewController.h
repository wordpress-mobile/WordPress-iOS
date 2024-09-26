#import <UIKit/UIKit.h>

@class Blog;
@class PublicizeConnection;

/**
 *	@brief	Controller to display Calypso sharing options
 */
@interface SharingDetailViewController : UITableViewController

/**
 *	@brief	Convenience initializer
 *
 *  @param  blog        the blog from where to read the information from
 *  @param  connection  the relevant publicize connection
 *
 *  @return New instance of SharingDetailViewController
 */
- (instancetype)initWithBlog:(Blog *)blog
         publicizeConnection:(PublicizeConnection *)connection;

@end
