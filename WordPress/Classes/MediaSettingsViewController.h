//
//  MediaSettingsViewController.h
//  WordPress
//
//  Created by Jeffrey Vanneste on 2013-01-05.
//  Copyright (c) 2013 WordPress. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <MediaPlayer/MediaPlayer.h>
#import "WordPressAppDelegate.h"
#import "Media.h"
#import "UITableViewActivityCell.h"
#import "WPPopoverBackgroundView.h"
#import "MediaSettings.h"

@interface MediaSettingsViewController : UIViewController <UIAlertViewDelegate, UIActionSheetDelegate, UITableViewDataSource, UITableViewDelegate, UIPickerViewDelegate, UIPickerViewDataSource, UITextFieldDelegate> {
	Media *media;
    NSArray *linkToOptionsList, *positioningOptionsList, *alignmentOptionsList;
    BOOL isShowingKeyboard;
    
    UIPickerView *pickerView;
    UIToolbar *toolbar;
    UIActionSheet *currentActionSheet;
    UIActionSheet *actionSheet;
    UIView *footerView;
    UIButton *deleteButton;
    IBOutlet UIBarButtonItem *cancelButton;
    UIPopoverController *popover;
    
    IBOutlet UITableView *tableView;
    IBOutlet UITableViewCell *linkToTableViewCell, *captionTableViewCell, *widthTableViewCell, *alignmentTableViewCell, *positioningTableViewCell, *mediaTableViewCell;
    IBOutlet UILabel *linkToLabel, *alignmentLabel, *positioningLabel, *imageSizeLabel,
        *linkToTitleLabel, *captionTitleLabel, *widthTitleLabel, *alignmentTitleLabel, *positioningTitleLabel;
    IBOutlet UIImageView *thumbnail;
    IBOutlet UITextField *captionTextField;
    IBOutlet UISlider *widthSlider;
}

@property (nonatomic, strong) Media *media;
@property (nonatomic, strong) MediaSettings *mediaSettings;

@end
