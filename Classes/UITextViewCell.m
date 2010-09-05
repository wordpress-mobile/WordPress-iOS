#import "UITextViewCell.h" 

// cell identifier for this custom cell
NSString *kCellTextView_ID = @"UITextViewCell_ID";

@implementation UITextViewCell
@synthesize textView;

//Helper method to create the workout cell from a nib file...
+ (UITextViewCell *) createNewTextCellFromNib { 
    NSArray *nibContents = [[NSBundle mainBundle] loadNibNamed:@"UITextViewCell" owner:self options:nil]; 
    NSEnumerator *nibEnumerator = [nibContents objectEnumerator]; 
    UITextViewCell *tCell = nil; 
    NSObject *nibItem = nil; 
    while((nibItem = [nibEnumerator nextObject]) != nil) { 
        if([nibItem isKindOfClass: [UITextViewCell class]]) { 
            tCell = (UITextViewCell*) nibItem; 
            if ([tCell.reuseIdentifier isEqualToString: kCellTextView_ID]) 
                break; // we have a winner 
            else 
                tCell = nil; 
        } 
    } 
    return tCell; 
} 

- (void)dealloc {
    [textView release];
    [super dealloc];
}

@end