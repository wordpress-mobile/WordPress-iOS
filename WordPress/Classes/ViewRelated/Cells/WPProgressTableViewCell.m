#import "WPProgressTableViewCell.h"
#import "MRProgress.h"

static void *ProgressObserverContext = &ProgressObserverContext;

NSString * const WPProgressImageThumbnailKey = @"WPProgressImageThumbnailKey";
@interface WPProgressTableViewCell ()

@property (nonatomic, strong) IBOutlet MRActivityIndicatorView * progressView;

@end

@implementation WPProgressTableViewCell {
    NSProgress *_progress;
}

- (id)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier
{
    self = [super initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:reuseIdentifier];
    if (self) {
        _progressView = [[MRActivityIndicatorView alloc] initWithFrame:CGRectMake(10.0,0.0,40.0,40.0)];
        _progressView.hidden = YES;
        self.accessoryView = _progressView;
    }
    return self;
}

- (void)dealloc
{
    [_progress removeObserver:self forKeyPath:NSStringFromSelector(@selector(fractionCompleted))];
}

- (void)prepareForReuse
{
    [self setProgress:nil];
    self.progressView.hidden = YES;
    self.progressView.hidesWhenStopped=YES;
    [self.progressView stopAnimating];
}

- (void)layoutSubviews
{
    [super layoutSubviews];
    self.imageView.frame = CGRectInset(self.imageView.frame, 0.0, 5.0);
}

#pragma mark - Progress handling

- (void) setProgress:(NSProgress *) progress {
    if (progress == _progress){
        return;
    }
    [_progress removeObserver:self forKeyPath:NSStringFromSelector(@selector(fractionCompleted))];

    _progress = progress;
    
    [_progress addObserver:self
                         forKeyPath:NSStringFromSelector(@selector(fractionCompleted))
                            options:NSKeyValueObservingOptionInitial
                            context:ProgressObserverContext];
    
    if (_progress.isCancellable){
        [self.progressView.stopButton addTarget:self action:@selector(stopPressed:) forControlEvents:UIControlEventTouchUpInside];
    }
    [self updateProgress];
}

- (void)updateProgress
{
    if (_progress.fractionCompleted < 1
        && !(_progress.totalUnitCount == 0 && _progress.completedUnitCount == 0)) {
        [_progressView startAnimating];
    } else {
        [_progressView stopAnimating];
    }

    self.progressView.mayStop = _progress.isCancellable;
    if ([_progress isCancelled]) {
        self.textLabel.text = NSLocalizedString(@"Cancelled", @"The action was cancelled");
        self.detailTextLabel.text = @"";
    } else if (_progress.totalUnitCount == 0 && _progress.completedUnitCount == 0) {
        self.textLabel.text = NSLocalizedString(@"Failed", @"The action failed");
        self.detailTextLabel.text = @"";
    } else if (_progress.fractionCompleted >= 1) {
        self.textLabel.text = NSLocalizedString(@"Completed", @"The action is completed");
        self.detailTextLabel.text = @"";
    } else {
        self.textLabel.text = [_progress localizedDescription];
        self.detailTextLabel.text = [_progress localizedAdditionalDescription];
    }
    [self.imageView setImage:_progress.userInfo[WPProgressImageThumbnailKey]];
}

#pragma mark - KVO

- (void)observeValueForKeyPath:(NSString *)keyPath
                      ofObject:(id)object
                        change:(NSDictionary *)change
                       context:(void *)context
{
    if (context == ProgressObserverContext && object == _progress) {
        [[NSOperationQueue mainQueue] addOperationWithBlock:^{
            [self updateProgress];
        }];
    } else {
        [super observeValueForKeyPath:keyPath ofObject:object change:change context:context];
    }
}

#pragma mark - Stop Button events

- (void) stopPressed:(id)sender
{
    [_progress cancel];
}

@end
