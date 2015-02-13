#import "EditReplyViewController.h"
#import "IOS7CorrectedTextView.h"
#import "SuggestionsTableView.h"
#import "SuggestionService.h"
#import "math.h"

static CGFloat const ERVCContentScrollMargin = 10.;

@interface EditReplyViewController() <UITextViewDelegate, SuggestionsTableViewDelegate>
@property (nonatomic, strong) NSNumber                       *siteID;
@property (nonatomic,   weak) IBOutlet IOS7CorrectedTextView *textView;
@property (nonatomic, strong) SuggestionsTableView           *suggestionsTableView;
@property (nonatomic)         bool                           hasCachedContentOffset;
@property (nonatomic)         CGPoint                        cachedContentOffset;
@end

@implementation EditReplyViewController

#pragma mark - Static Helpers

+ (instancetype)newReplyViewControllerForSiteID:(NSNumber *)siteID
{
    return [[[self class] alloc] initWithNibName:NSStringFromClass([self class]) bundle:nil siteID:siteID];
}

#pragma mark - Lifecycle

- (instancetype)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil siteID:(NSNumber *)siteID
{
    if (self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil]) {
        _siteID = siteID;
    }
    
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    self.title = NSLocalizedString(@"Reply", @"Comment Reply Screen title");
    self.navigationItem.rightBarButtonItem.title = NSLocalizedString(@"Send", @"Verb, submit a comment reply");
    self.content = [NSString string];
    
    [self attachSuggestionsViewIfNeeded];
}

#pragma mark - Private helpers

- (void)attachSuggestionsViewIfNeeded
{
    self.hasCachedContentOffset = false;
    self.cachedContentOffset = CGPointZero;
    
    if ([[SuggestionService sharedInstance] shouldShowSuggestionsForSiteID:self.siteID]) {        
        // attach the suggestions view
        self.suggestionsTableView = [[SuggestionsTableView alloc] initWithSiteID:self.siteID];
        self.suggestionsTableView.suggestionsDelegate = self;
        self.suggestionsTableView.useTransparentHeader = YES;
        [self.suggestionsTableView setTranslatesAutoresizingMaskIntoConstraints:NO];
        [self.view addSubview:self.suggestionsTableView];
        
        // Pin the suggestions view left and right edges to the text view edges
        NSDictionary *views = @{@"suggestionsview": self.suggestionsTableView };
        [self.view addConstraint:[NSLayoutConstraint constraintWithItem:self.suggestionsTableView
                                                              attribute:NSLayoutAttributeLeft
                                                              relatedBy:NSLayoutRelationEqual
                                                                 toItem:self.textView
                                                              attribute:NSLayoutAttributeLeft
                                                             multiplier:1
                                                               constant:0]];
        
        [self.view addConstraint:[NSLayoutConstraint constraintWithItem:self.suggestionsTableView
                                                              attribute:NSLayoutAttributeRight
                                                              relatedBy:NSLayoutRelationEqual
                                                                 toItem:self.textView
                                                              attribute:NSLayoutAttributeRight
                                                             multiplier:1
                                                               constant:0]];
        
        // Pin the suggestions view top to the super view top, less a 30 pt margin
        [self.view addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"V:|-30.0-[suggestionsview]"
                                                                          options:0
                                                                          metrics:nil
                                                                            views:views]];
        
        // Pin the suggestions view bottom to the bottom of the reply box
        [self.view addConstraint:[NSLayoutConstraint constraintWithItem:self.suggestionsTableView
                                                              attribute:NSLayoutAttributeBottom
                                                              relatedBy:NSLayoutRelationEqual
                                                                 toItem:self.textView
                                                              attribute:NSLayoutAttributeBottom
                                                             multiplier:1
                                                               constant:0]];
        
        // listen to textView changes
        self.textView.delegate = self;
    }
}

#pragma mark - UITextViewDelegate

- (BOOL)textView:(UITextView *)textView shouldChangeTextInRange:(NSRange)range replacementText:(NSString *)text
{
    // Get all the text
    NSString *textViewText = textView.text;
    NSRange textViewRange = NSMakeRange(0, range.location);
    NSString *pretext = [[textViewText substringWithRange:textViewRange] stringByAppendingString:text];
    NSArray *words = [pretext componentsSeparatedByCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
    [self.suggestionsTableView showSuggestionsForWord:[words lastObject]];
    
    return YES;
}

#pragma mark - SuggestionsTableViewDelegate

- (void)suggestionsTableView:(SuggestionsTableView *)suggestionsTableView didChangeTableBounds:(CGRect)bounds
{
    CGRect textViewBounds = self.textView.bounds;
    CGRect caretRect = [self.textView caretRectForPosition:self.textView.selectedTextRange.end];
    
    // If we are showing suggestions, mind the bottom of the caret, to make sure the typing
    // insertion point is covered by the suggestions below
    
    if (bounds.size.height > 0) {
        CGPoint contentOffset = [self.textView contentOffset];
        
        // If we haven't cached the contentOffset already, do so now
        if (!self.hasCachedContentOffset) {
            self.hasCachedContentOffset = true;
            self.cachedContentOffset = contentOffset;
        }
        
        CGFloat caretBottom = caretRect.origin.y + caretRect.size.height - contentOffset.y;        
        CGFloat gapBottom = textViewBounds.size.height - bounds.size.height;
        if (caretBottom > gapBottom) {
            contentOffset.y += (caretBottom - gapBottom) + ERVCContentScrollMargin; // plus a little more
            [self.textView setContentOffset:contentOffset animated:YES];
        }
    } else {
        // if the table has collapsed to zero height, and we have a cached content offset
        // restore that offset now to avoid the scrolling jumping suddenly if they add
        // a carriage return after selecting a mention
        if (self.hasCachedContentOffset) {
            [self.textView setContentOffset:self.cachedContentOffset animated:YES];
            self.hasCachedContentOffset = false;
            self.cachedContentOffset = CGPointZero;
        }
    }
}

- (void)suggestionsTableView:(SuggestionsTableView *)suggestionsTableView didSelectSuggestion:(NSString *)suggestion forSearchText:(NSString *)text
{
    UITextRange *selectedRange = [self.textView selectedTextRange];
    NSInteger offset = - text.length;
    UITextPosition *newPosition = [self.textView positionFromPosition:selectedRange.start offset:offset];
    UITextRange *newRange = [self.textView textRangeFromPosition:newPosition toPosition:selectedRange.start];
    [self.textView replaceRange:newRange withText:suggestion];
    [suggestionsTableView showSuggestionsForWord:@""];
}

@end
