#import "WPTableViewProgressCell.h"

static void *ProgressObserverContext = &ProgressObserverContext;

NSString * const WPProgressImageThumbnailKey = @"WPProgressImageThumbnailKey";

@implementation WPTableViewProgressCell {
    NSProgress * _progress;
}

- (id)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier {
    self = [super initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:reuseIdentifier];
    if (self) {
        _progressView = [[UIProgressView alloc] initWithProgressViewStyle:UIProgressViewStyleDefault];
        _progressView.frame = CGRectMake(0,0,50,50);
        self.accessoryView = _progressView;
    }
    return self;
}

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
    [self updateProgress];
}

- (void) updateProgress
{
    [self.progressView setProgress:_progress.fractionCompleted animated:YES];
    self.textLabel.text = [_progress localizedDescription];
    self.detailTextLabel.text = [_progress localizedAdditionalDescription];
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

- (void)prepareForReuse
{
    [self setProgress:nil];
    self.progressView.progress = 0;
}

@end
