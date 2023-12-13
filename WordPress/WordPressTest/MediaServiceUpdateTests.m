#import <OCMock/OCMock.h>
#import <XCTest/XCTest.h>
#import "Blog.h"
#import "WordPressTest-Swift.h"
@import WordPressKit;

// Redefine `WPAccount` to make `wordPressComRestApi` writable.
@interface WPAccount ()
@property (nonatomic, readwrite) WordPressComRestApi *wordPressComRestApi;
@end

// Re-implement `MediaService` to mock the remote service `MediaServiceRemote`.
@interface MediaServiceForStubbing : MediaService
@property (nonatomic, strong) MediaServiceRemoteREST *remoteForStubbing;
@end

@implementation MediaServiceForStubbing
- (id <MediaServiceRemote>)remoteForBlog:(Blog *)blog
{
    return self.remoteForStubbing;
}
@end


@interface MediaServiceUpdateTests : XCTestCase
@property (nonatomic, strong) id<CoreDataStack> manager;
@property (nonatomic, strong) Blog *blog;
@property (nonatomic, strong) MediaServiceForStubbing *service;
@property (nonatomic, strong) NSDate *mediaCreationDate;
@end

@implementation MediaServiceUpdateTests

- (void)setUp
{
    [super setUp];
    
    self.manager = [self coreDataStackForTesting];
    
    WordPressComRestApi *api = OCMStrictClassMock([WordPressComRestApi class]);
    
    Blog *blog = [ModelTestHelper insertDotComBlogWithContext:self.manager.mainContext];
    blog.account.wordPressComRestApi = api;
    blog.dotComID = @1;
    self.blog = blog;
    
    MediaServiceForStubbing *service = [[MediaServiceForStubbing alloc] initWithManagedObjectContext:self.manager.mainContext];
    MediaServiceRemoteREST *remoteService = OCMStrictClassMock([MediaServiceRemoteREST class]);
    service.remoteForStubbing = remoteService;
    self.service = service;
    
    self.mediaCreationDate = [NSDate date];
}

- (void)tearDown
{
    [super tearDown];
    
    self.blog = nil;
    self.service = nil;
    self.manager = nil;
    self.mediaCreationDate = nil;
}

- (void)testUpdateMediaWorks
{
    Media *media = [self generateMedia: @100];
    
    // Check that all media details are passed for updating the media item.
    BOOL (^checkRemoteMedia)(id obj) = ^BOOL(RemoteMedia *remoteMedia) {
        if (![remoteMedia.mediaID isEqualToNumber:media.mediaID]) {
            return NO;
        } else if (![remoteMedia.url isEqual:[NSURL URLWithString:media.remoteURL]]) {
            return NO;
        } else if (![remoteMedia.largeURL isEqual:[NSURL URLWithString:media.remoteLargeURL]]) {
            return NO;
        } else if (![remoteMedia.mediumURL isEqual:[NSURL URLWithString:media.remoteMediumURL]]) {
            return NO;
        } else if (![remoteMedia.date isEqualToDate:media.creationDate]) {
            return NO;
        } else if (![remoteMedia.file isEqualToString:media.filename]) {
            return NO;
        } else if (![remoteMedia.extension isEqualToString:[media fileExtension]]) {
            return NO;
        } else if (![remoteMedia.title isEqualToString:media.title]) {
            return NO;
        } else if (![remoteMedia.caption isEqualToString:media.caption]) {
            return NO;
        } else if (![remoteMedia.descriptionText isEqualToString:media.desc]) {
            return NO;
        } else if (![remoteMedia.alt isEqualToString:media.alt]) {
            return NO;
        } else if (![remoteMedia.height isEqualToNumber:media.height]) {
            return NO;
        } else if (![remoteMedia.width isEqualToNumber:media.width]) {
            return NO;
        } else if (![remoteMedia.localURL isEqual:media.absoluteLocalURL]) {
            return NO;
        } else if (![remoteMedia.mimeType isEqualToString:media.mimeType]) {
            return NO;
        } else if (![remoteMedia.videopressGUID isEqualToString:media.videopressGUID]) {
            return NO;
        } else if (![remoteMedia.remoteThumbnailURL isEqualToString:media.remoteThumbnailURL]) {
            return NO;
        } else if (![remoteMedia.postID isEqualToNumber:media.postID]) {
            return NO;
        }
        return YES;
    };
    
    MediaServiceRemoteREST *remote = self.service.remoteForStubbing;
    OCMStub([remote updateMedia:[OCMArg checkWithBlock:checkRemoteMedia] success:[OCMArg isNotNil] failure:[OCMArg isNotNil]]);
    
    XCTAssertNoThrow([self.service updateMedia:media success:^{} failure:^(NSError * _Nonnull __unused error) {}]);
}

- (void)testUpdateMultpipleMediaWorks
{
    Media *media = [self generateMedia: @100];
    // We use the same details except `mediaId` in the defined media items.
    NSArray<Media *> *mediaItems = [NSArray arrayWithObjects: media, [self generateMedia:@101], nil];
    
    // Check that all media details are passed for updating the media items.
    BOOL (^checkRemoteMedia)(id obj) = ^BOOL(RemoteMedia *remoteMedia) {
        if (![remoteMedia.mediaID isEqualToNumber:mediaItems[0].mediaID] &&
            ![remoteMedia.mediaID isEqualToNumber:mediaItems[1].mediaID])
        {
            return NO;
        } else if (![remoteMedia.url isEqual:[NSURL URLWithString:media.remoteURL]]) {
            return NO;
        } else if (![remoteMedia.largeURL isEqual:[NSURL URLWithString:media.remoteLargeURL]]) {
            return NO;
        } else if (![remoteMedia.mediumURL isEqual:[NSURL URLWithString:media.remoteMediumURL]]) {
            return NO;
        } else if (![remoteMedia.date isEqualToDate:media.creationDate]) {
            return NO;
        } else if (![remoteMedia.file isEqualToString:media.filename]) {
            return NO;
        } else if (![remoteMedia.extension isEqualToString:[media fileExtension]]) {
            return NO;
        } else if (![remoteMedia.title isEqualToString:media.title]) {
            return NO;
        } else if (![remoteMedia.caption isEqualToString:media.caption]) {
            return NO;
        } else if (![remoteMedia.descriptionText isEqualToString:media.desc]) {
            return NO;
        } else if (![remoteMedia.alt isEqualToString:media.alt]) {
            return NO;
        } else if (![remoteMedia.height isEqualToNumber:media.height]) {
            return NO;
        } else if (![remoteMedia.width isEqualToNumber:media.width]) {
            return NO;
        } else if (![remoteMedia.localURL isEqual:media.absoluteLocalURL]) {
            return NO;
        } else if (![remoteMedia.mimeType isEqualToString:media.mimeType]) {
            return NO;
        } else if (![remoteMedia.videopressGUID isEqualToString:media.videopressGUID]) {
            return NO;
        } else if (![remoteMedia.remoteThumbnailURL isEqualToString:media.remoteThumbnailURL]) {
            return NO;
        } else if (![remoteMedia.postID isEqualToNumber:media.postID]) {
            return NO;
        }
        return YES;
    };
    
    MediaServiceRemoteREST *remote = self.service.remoteForStubbing;
    OCMStub([remote updateMedia:[OCMArg checkWithBlock:checkRemoteMedia] success:[OCMArg isNotNil] failure:[OCMArg isNotNil]]);
    
    XCTAssertNoThrow([self.service updateMedia:mediaItems overallSuccess:^{} failure:^(NSError * _Nonnull __unused error) {}]);
}

- (void)testUpdateMediaWithSpecificFieldsWorks
{
    Media *media = [self generateMedia: @100];
    
    // Check that only `title` and `postID` details are passed for updating the media item.
    // NOTE: `mediaID` is always passed as it's mandatory for the update.
    BOOL (^checkRemoteMedia)(id obj) = ^BOOL(RemoteMedia *remoteMedia) {
        if (![remoteMedia.mediaID isEqualToNumber:media.mediaID]) {
            return NO;
        } else if (![remoteMedia.title isEqualToString:media.title]) {
            return NO;
        } else if (![remoteMedia.postID isEqualToNumber:media.postID]) {
            return NO;
        } else if (remoteMedia.url != nil) {
            return NO;
        } else if (remoteMedia.largeURL != nil) {
            return NO;
        } else if (remoteMedia.mediumURL != nil) {
            return NO;
        } else if (remoteMedia.date != nil) {
            return NO;
        } else if (remoteMedia.file != nil) {
            return NO;
        } else if (remoteMedia.extension != nil) {
            return NO;
        } else if (remoteMedia.caption != nil) {
            return NO;
        } else if (remoteMedia.descriptionText != nil) {
            return NO;
        } else if (remoteMedia.alt != nil) {
            return NO;
        } else if (remoteMedia.height != nil) {
            return NO;
        } else if (remoteMedia.width != nil) {
            return NO;
        } else if (remoteMedia.localURL != nil) {
            return NO;
        } else if (remoteMedia.mimeType != nil) {
            return NO;
        } else if (remoteMedia.videopressGUID != nil) {
            return NO;
        } else if (remoteMedia.remoteThumbnailURL != nil) {
            return NO;
        }
        return YES;
    };
    
    MediaServiceRemoteREST *remote = self.service.remoteForStubbing;
    OCMStub([remote updateMedia:[OCMArg checkWithBlock:checkRemoteMedia] success:[OCMArg isNotNil] failure:[OCMArg isNotNil]]);
    
    NSArray *fieldsToUpdate = [NSArray arrayWithObjects: @"postID", @"title", nil];
    XCTAssertNoThrow([self.service updateMedia:media fieldsToUpdate:fieldsToUpdate success:^{} failure:^(NSError * _Nonnull __unused error) {}]);
}

- (void)testUpdateMultpipleMediaWithSpecificFieldsWorks
{
    Media *media = [self generateMedia: @100];
    // We use the same details except `mediaId` in the defined media items.
    NSArray<Media *> *mediaItems = [NSArray arrayWithObjects: media, [self generateMedia:@101], nil];
    
    // Check that only `title` and `postID` details are passed for updating the media item.
    // NOTE: `mediaID` is always passed as it's mandatory for the update.
    BOOL (^checkRemoteMedia)(id obj) = ^BOOL(RemoteMedia *remoteMedia) {
        if (![remoteMedia.mediaID isEqualToNumber:mediaItems[0].mediaID] &&
            ![remoteMedia.mediaID isEqualToNumber:mediaItems[1].mediaID])
        {
            return NO;
        } else if (![remoteMedia.title isEqualToString:media.title]) {
            return NO;
        } else if (![remoteMedia.postID isEqualToNumber:media.postID]) {
            return NO;
        } else if (remoteMedia.url != nil) {
            return NO;
        } else if (remoteMedia.largeURL != nil) {
            return NO;
        } else if (remoteMedia.mediumURL != nil) {
            return NO;
        } else if (remoteMedia.date != nil) {
            return NO;
        } else if (remoteMedia.file != nil) {
            return NO;
        } else if (remoteMedia.extension != nil) {
            return NO;
        } else if (remoteMedia.caption != nil) {
            return NO;
        } else if (remoteMedia.descriptionText != nil) {
            return NO;
        } else if (remoteMedia.alt != nil) {
            return NO;
        } else if (remoteMedia.height != nil) {
            return NO;
        } else if (remoteMedia.width != nil) {
            return NO;
        } else if (remoteMedia.localURL != nil) {
            return NO;
        } else if (remoteMedia.mimeType != nil) {
            return NO;
        } else if (remoteMedia.videopressGUID != nil) {
            return NO;
        } else if (remoteMedia.remoteThumbnailURL != nil) {
            return NO;
        }
        return YES;
    };
    
    MediaServiceRemoteREST *remote = self.service.remoteForStubbing;
    OCMStub([remote updateMedia:[OCMArg checkWithBlock:checkRemoteMedia] success:[OCMArg isNotNil] failure:[OCMArg isNotNil]]);
    
    NSArray *fieldsToUpdate = [NSArray arrayWithObjects: @"postID", @"title", nil];
    XCTAssertNoThrow([self.service updateMedia:mediaItems fieldsToUpdate:fieldsToUpdate overallSuccess:^{} failure:^(NSError * _Nonnull __unused error) {}]);
}

/// Helper to generate a Media object with test data.
- (Media *)generateMedia:(NSNumber *)mediaId {
    Media *media = [NSEntityDescription
                    insertNewObjectForEntityForName:[Media entityName]
                    inManagedObjectContext:self.manager.mainContext];
    media.mediaID = mediaId;
    media.remoteURL = @"https://wordpress.com/remote";
    media.remoteLargeURL = @"https://wordpress.com/remote-large";
    media.remoteMediumURL = @"https://wordpress.com/remote-medium";
    media.creationDate = self.mediaCreationDate;
    media.filename = @"file.png";
    media.title = @"Media title";
    media.caption = @"Media caption";
    media.desc = @"Media description";
    media.alt = @"Media alt";
    media.height = @150;
    media.width = @250;
    media.localURL = @"file:///file.png";
    media.videopressGUID = @"AbCDe";
    media.remoteThumbnailURL = @"https://wordpress.com/remote-thumbnail";
    media.postID = @1;
    return media;
}

@end
