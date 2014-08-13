#import <UIKit/UIKit.h>
#import "WPTableViewCell.h"
#import "NoteBlockTableViewCell.h"
#import <DTCoreText/DTCoreText.h>



@interface NoteBlockTextTableViewCell : WPTableViewCell <NoteBlockTableViewCell>

@property (nonatomic,   weak) IBOutlet DTAttributedLabel *attributedLabel;

@property (nonatomic, strong) NSAttributedString         *attributedText;
@property (nonatomic,   copy) NotificationUrlHandler     onUrlClick;

@end
