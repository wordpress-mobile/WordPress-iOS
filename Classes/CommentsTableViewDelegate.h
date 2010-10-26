//
//  CommentsTableViewDelegate.h
//  WordPress
//
//  Created by Josh Bassett on 2/07/09.
//

#import <UIKit/UIKit.h>

@protocol CommentsTableViewDelegate<UITableViewDelegate>
-(void)tableView : (UITableView *)tableView didCheckRowAtIndexPath : (NSIndexPath *)indexPath;
@end
