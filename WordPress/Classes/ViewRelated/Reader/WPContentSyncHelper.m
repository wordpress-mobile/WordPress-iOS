#import "WPContentSyncHelper.h"

@interface WPContentSyncHelper()

@property(nonatomic, readwrite) BOOL isSyncing;
@property(nonatomic, readwrite) BOOL isLoadingMore;
@property(nonatomic, readwrite) BOOL hasMoreContent;

@end

@implementation WPContentSyncHelper

#pragma mark - Life Cycle Methods

- (instancetype)init
{
    self = [super init];
    if (self) {
        _hasMoreContent = YES;
    }
    return self;
}


#pragma mark - Public Methods

#pragma mark - Accessors

- (void)setHasMoreContent:(BOOL)hasMoreContent
{
    if (_hasMoreContent == hasMoreContent) {
        return;
    }

    _hasMoreContent = hasMoreContent;

    if (!_hasMoreContent && [self.delegate respondsToSelector:@selector(hasNoMoreContent)]) {
        [self.delegate hasNoMoreContent];
    }
}


#pragma mark - Syncing

- (BOOL)syncContent
{
    return [self syncContentViaUserInteraction:NO];
}

- (BOOL)syncContentViaUserInteraction
{
    return [self syncContentViaUserInteraction:YES];
}

- (BOOL)syncContentViaUserInteraction:(BOOL)userInteraction
{
    if (self.isSyncing) {
        return NO;
    }

    self.isSyncing = YES;
    [self.delegate syncHelper:self syncContentWithUserInteraction:userInteraction success:^(NSUInteger count) {
        self.hasMoreContent = (count > 0);
        [self syncContentEnded];
    } failure:^(NSError *error) {
        [self syncContentEnded];
    }];

    return YES;
}

- (BOOL)syncMoreContent
{
    if (self.isSyncing || !self.hasMoreContent) {
        return NO;
    }

    self.isSyncing = YES;
    self.isLoadingMore = YES;
    [self.delegate syncHelper:self syncMoreWithSuccess:^(NSUInteger count) {
        self.isLoadingMore = NO;
        self.hasMoreContent = (count > 0);
        [self syncContentEnded];
    } failure:^(NSError *error) {
        [self syncContentEnded];
    }];

    return YES;
}


#pragma mark - Private Methods

- (void)syncContentEnded
{
    self.isSyncing = NO;
    self.isLoadingMore = NO;

    if([self.delegate respondsToSelector:@selector(syncContentEnded)]) {
        [self.delegate syncContentEnded];
    }
}

@end
