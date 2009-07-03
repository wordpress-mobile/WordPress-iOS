//
//  BlogTabViewController.h
//  WordPress
//
//  Created by Gareth Townsend on 26/06/09.
//

#import <UIKit/UIKit.h>


@interface BlogTabViewController : UIViewController <UITabBarDelegate> {
    NSArray *viewControllers;
    
    IBOutlet UITabBar *tabBar;
    IBOutlet UITabBarItem *postsTabBarItem;
    IBOutlet UITabBarItem *pagesTabBarItem;
    IBOutlet UITabBarItem *commentsTabBarItem;
    
    UIViewController *selectedViewController;
}

@property (nonatomic, retain) NSArray *viewControllers;

@property (nonatomic, retain) IBOutlet UITabBar *tabBar;
@property (nonatomic, retain) IBOutlet UITabBarItem *postsTabBarItem;
@property (nonatomic, retain) IBOutlet UITabBarItem *pagesTabBarItem;
@property (nonatomic, retain) IBOutlet UITabBarItem *commentsTabBarItem;

@property (nonatomic, retain) UIViewController *selectedViewController;

@end
