#import "UILoadMoreCell.h" 

// cell identifier for this custom cell
NSString *kCellLoadMore_ID = @"kCellLoadMore_ID";

@implementation UILoadMoreCell
@synthesize spinner, mainLabel, subtitleLabel, postType, postCount;

// Helper method to create the workout cell from a nib file...
+ (UILoadMoreCell *)createNewLoadMoreCellFromNib { 
    NSArray *nibContents = [[NSBundle mainBundle] loadNibNamed:@"UILoadMoreCell" owner:self options:nil]; 
    NSEnumerator *nibEnumerator = [nibContents objectEnumerator]; 
    UILoadMoreCell *tCell = nil; 
    NSObject *nibItem = nil; 
    while((nibItem = [nibEnumerator nextObject]) != nil) { 
        if([nibItem isKindOfClass: [UILoadMoreCell class]]) { 
            tCell = (UILoadMoreCell *) nibItem; 
            if ([tCell.reuseIdentifier isEqualToString: kCellLoadMore_ID]) 
                break; // we have a winner 
            else 
                tCell = nil; 
        } 
    }
	
    return tCell; 
}

- (void)dealloc {
	[postType release];
    [spinner release];
    [mainLabel release];
    [subtitleLabel release];
    [super dealloc];
}

@end