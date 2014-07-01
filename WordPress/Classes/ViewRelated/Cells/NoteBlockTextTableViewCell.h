#import <UIKit/UIKit.h>
#import "WPTableViewCell.h"
#import "NoteBlockTableViewCell.h"



@interface NoteBlockTextTableViewCell : WPTableViewCell <NoteBlockTableViewCell>

@property (nonatomic, strong) NSAttributedString        *attributedText;
@property (nonatomic, copy)   NotificationUrlHandler    onUrlClick;

@end
