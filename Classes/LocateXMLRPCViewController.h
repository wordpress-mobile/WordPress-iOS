//
//  LocateXMLRPC.h
//  WordPress
//
//  Created by John Bickerstaff on 7/11/09.
//  
//

#import <UIKit/UIKit.h>


@interface LocateXMLRPCViewController : UIViewController <UITextFieldDelegate> {
	
	IBOutlet UIBarButtonItem *cancelXMLRPCButton;
    IBOutlet UIBarButtonItem *saveXMLRPCButton;
	IBOutlet UITableView *xmlrpcURLTableView;
	IBOutlet UITableViewCell *xmlrpcURLTableViewCell;
	IBOutlet UITextField *xmlrpcURLTextField;
	IBOutlet UILabel *xmlrpcURLLabel;
	BOOL didUserEnterURL;
	
	
	
	

}


@property (nonatomic, retain) IBOutlet UITextField * xmlrpcURLTextField;
@property (nonatomic, retain) IBOutlet UITableView *xmlrpcURLTableView;


//- (void)saveUserEnteredXMLRPCEndpointURL;
- (void) saveUserEnteredXMLRPCEndpointToCurrentBlog:(UITextField *)textField;
- (IBAction)saveXMLRPCLocation:(id)sender;
- (IBAction)cancel:(id)sender;

@end
