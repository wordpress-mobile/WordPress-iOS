#import <UIKit/UIKit.h>



// Forward Classes
@class ReplyTextView;
@class SuggestionsTableView;
@class NotificationMediaDownloader;
@class KeyboardDismissHelper;



// TODO: JLP 7.26.2016
// This category is a temporary workaround, to be used during the Swift Migration.
// Will be nuked ASAP.
//
@interface NotificationDetailsViewController ()

// Outlets
@property (nonatomic, strong) IBOutlet UIStackView          *stackView;
@property (nonatomic, strong) IBOutlet UITableView          *tableView;
@property (nonatomic, strong) IBOutlet UIGestureRecognizer  *tableGesturesRecognizer;
@property (nonatomic, strong) IBOutlet NSLayoutConstraint   *topLayoutConstraint;
@property (nonatomic, strong) IBOutlet NSLayoutConstraint   *centerLayoutConstraint;
@property (nonatomic, strong) IBOutlet NSLayoutConstraint   *bottomLayoutConstraint;
@property (nonatomic, strong) ReplyTextView                 *replyTextView;
@property (nonatomic, strong) SuggestionsTableView          *suggestionsTableView;

// Table Helpers
@property (nonatomic, strong) NSDictionary                  *layoutIdentifierMap;
@property (nonatomic, strong) NSDictionary                  *reuseIdentifierMap;
@property (nonatomic, strong) NSArray                       *blockGroups;

// Helpers
@property (nonatomic, strong) NotificationMediaDownloader   *mediaDownloader;
@property (nonatomic, strong) KeyboardDismissHelper         *keyboardManager;

// Model
@property (nonatomic, strong) Notification                  *note;

- (void)reloadData;

@end
