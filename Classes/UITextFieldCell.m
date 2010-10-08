#import "UITextFieldCell.h" 

// cell identifier for this custom cell
NSString *kCellTextField_ID = @"UITextFieldCell_ID";

@implementation UITextFieldCell
@synthesize titleLabel, textField;

//Helper method to create the workout cell from a nib file...
+ (UITextFieldCell *) createNewTextCellFromNib { 
    NSArray *nibContents = [[NSBundle mainBundle] loadNibNamed:@"UITextFieldCell" owner:self options:nil]; 
    NSEnumerator *nibEnumerator = [nibContents objectEnumerator]; 
    UITextFieldCell *tCell = nil; 
    NSObject *nibItem = nil; 
    while((nibItem = [nibEnumerator nextObject]) != nil) { 
        if([nibItem isKindOfClass: [UITextFieldCell class]]) { 
            tCell = (UITextFieldCell*) nibItem; 
            if ([tCell.reuseIdentifier isEqualToString: kCellTextField_ID]) 
                break; // we have a winner 
            else 
                tCell = nil; 
        } 
    } 
    return tCell; 
} 

- (void)dealloc {
	[titleLabel release];
	[textField release];
    [super dealloc];
}

@end