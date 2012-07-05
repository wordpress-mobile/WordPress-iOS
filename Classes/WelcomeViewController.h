//
//  WelcomeViewController.h
//  WordPress
//
//  Created by Dan Roundhill on 5/5/10.
//

#import <UIKit/UIKit.h>

@interface WelcomeViewController : UIViewController 

@property (nonatomic, retain) IBOutlet UIView *logoView;
@property (nonatomic, retain) IBOutlet UIView *buttonView;
@property (nonatomic, retain) IBOutlet UIButton *infoButton;
@property (nonatomic, retain) IBOutlet UIButton *orgBlogButton;
@property (nonatomic, retain) IBOutlet UIButton *addBlogButton;
@property (nonatomic, retain) IBOutlet UIButton *createBlogButton;
@property (nonatomic, retain) IBOutlet UILabel *createLabel;

- (IBAction)handleInfoTapped:(id)sender;
- (IBAction)handleOrgBlogTapped:(id)sender;
- (IBAction)handleAddBlogTapped:(id)sender;
- (IBAction)handleCreateBlogTapped:(id)sender;

- (IBAction)cancel:(id)sender;
- (void)automaticallyDismissOnLoginActions; //used when shown as a Real Welcome controller
- (void)showAboutView;

@end
