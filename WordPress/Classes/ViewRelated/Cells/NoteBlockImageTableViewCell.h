#import <UIKit/UIKit.h>
#import "WPTableViewCell.h"
#import "NoteBlockTableViewCell.h"



@interface NoteBlockImageTableViewCell : WPTableViewCell <NoteBlockTableViewCell>

@property (nonatomic, strong) NSURL *imageURL;

@end
