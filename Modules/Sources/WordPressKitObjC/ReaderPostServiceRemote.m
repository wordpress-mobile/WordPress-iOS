#import "ReaderPostServiceRemote.h"
#import "RemoteReaderPost.h"
#import "RemoteSourcePostAttribution.h"
#import "ReaderTopicServiceRemote.h"
#import "WPKitDateUtils.h"
#import "NSString+Helpers.h"
#import "WPMapFilterReduce.h"
#import "WordPressComRestApiErrorDomain.h"

@import NSObject_SafeExpectations;

NSString * const PostRESTKeyPosts = @"posts";

// Param keys
NSString * const ParamsKeyAlgorithm = @"algorithm";
NSString * const ParamKeyBefore = @"before";
NSString * const ParamKeyMeta = @"meta";
NSString * const ParamKeyNumber = @"number";
NSString * const ParamKeyOffset = @"offset";
NSString * const ParamKeyOrder = @"order";
NSString * const ParamKeyDescending = @"DESC";
NSString * const ParamKeyMetaValue = @"site,feed";

@implementation ReaderPostServiceRemote

- (void)fetchPostsFromEndpoint:(NSURL *)endpoint
                     algorithm:(NSString *)algorithm
                         count:(NSUInteger)count
                        before:(NSDate *)date
                       success:(void (^)(NSArray<RemoteReaderPost *> *posts, NSString *algorithm))success
                       failure:(void (^)(NSError *error))failure
{
    NSNumber *numberToFetch = @(count);
    NSMutableDictionary *params = [@{
                                     ParamKeyNumber:numberToFetch,
                                     ParamKeyBefore: [WPKitDateUtils isoStringFromDate:date],
                                     ParamKeyOrder: ParamKeyDescending,
                                     ParamKeyMeta: ParamKeyMetaValue
                                     } mutableCopy];
    if (algorithm) {
        params[ParamsKeyAlgorithm] = algorithm;
    }

    [self fetchPostsFromEndpoint:endpoint withParameters:params success:success failure:failure];
}

- (void)fetchPostsFromEndpoint:(NSURL *)endpoint
                     algorithm:(NSString *)algorithm
                         count:(NSUInteger)count
                        offset:(NSUInteger)offset
                       success:(void (^)(NSArray<RemoteReaderPost *> *posts, NSString *algorithm))success
                       failure:(void (^)(NSError *))failure
{
    NSMutableDictionary *params = [@{
                                     ParamKeyNumber:@(count),
                                     ParamKeyOffset: @(offset),
                                     ParamKeyOrder: ParamKeyDescending,
                                     ParamKeyMeta: ParamKeyMetaValue
                                     } mutableCopy];
    if (algorithm) {
        params[ParamsKeyAlgorithm] = algorithm;
    }
    [self fetchPostsFromEndpoint:endpoint withParameters:params success:success failure:failure];
}

- (void)fetchPost:(NSUInteger)postID
         fromSite:(NSUInteger)siteID
           isFeed:(BOOL)isFeed
          success:(void (^)(RemoteReaderPost *post))success
          failure:(void (^)(NSError *error))failure {

    NSString *feedType = (isFeed) ? @"feed" : @"sites";
    NSString *path = [NSString stringWithFormat:@"read/%@/%lu/posts/%lu/?meta=site", feedType, (unsigned long)siteID, (unsigned long)postID];

    NSString *requestUrl = [self pathForEndpoint:path
                                     withVersion:WordPressComRESTAPIVersion_1_2];

    [self.wordPressComRESTAPI get:requestUrl
           parameters:nil
              success:^(id responseObject, NSHTTPURLResponse *httpResponse) {
                  if (!success) {
                      return;
                  }

                  dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_LOW, 0), ^{
                      // Do all of this work on a background thread, then call success on the main thread.
                      // Do this to avoid any chance of blocking the UI while parsing.
                      RemoteReaderPost *post = [[RemoteReaderPost alloc] initWithDictionary: (NSDictionary *)responseObject];
                      dispatch_async(dispatch_get_main_queue(), ^{
                          success(post);
                      });
                  });

              } failure:^(NSError *error, NSHTTPURLResponse *httpResponse) {
                  if (failure) {
                      failure(error);
                  }
              }];
}

- (void)likePost:(NSUInteger)postID
         forSite:(NSUInteger)siteID
         success:(void (^)(void))success
         failure:(void (^)(NSError *error))failure
{
    NSString *path = [NSString stringWithFormat:@"sites/%lu/posts/%lu/likes/new", (unsigned long)siteID, (unsigned long)postID];
    NSString *requestUrl = [self pathForEndpoint:path
                                     withVersion:WordPressComRESTAPIVersion_1_1];

    [self.wordPressComRESTAPI post:requestUrl parameters:nil success:^(id responseObject, NSHTTPURLResponse *httpResponse) {
        if (success) {
            success();
        }
    } failure:^(NSError *error, NSHTTPURLResponse *httpResponse) {
        if (failure) {
            failure(error);
        }
    }];
}

- (void)unlikePost:(NSUInteger)postID
           forSite:(NSUInteger)siteID
           success:(void (^)(void))success
           failure:(void (^)(NSError *error))failure
{
    NSString *path = [NSString stringWithFormat:@"sites/%lu/posts/%lu/likes/mine/delete", (unsigned long)siteID, (unsigned long)postID];
    NSString *requestUrl = [self pathForEndpoint:path
                                     withVersion:WordPressComRESTAPIVersion_1_1];

    [self.wordPressComRESTAPI post:requestUrl parameters:nil success:^(id responseObject, NSHTTPURLResponse *httpResponse) {
        if (success) {
            success();
        }
    } failure:^(NSError *error, NSHTTPURLResponse *httpResponse) {
        if (failure) {
            failure(error);
        }
    }];
}

- (NSString *)endpointUrlForSearchPhrase:(NSString *)phrase
{
    NSAssert([phrase length] > 0, @"A search phrase is required.");

    NSString *endpoint = [NSString stringWithFormat:@"read/search?q=%@", [phrase wpkit_stringByUrlEncoding]];
    NSString *absolutePath = [self pathForEndpoint:endpoint withVersion:WordPressComRESTAPIVersion_1_2];
    NSURL *url = [NSURL URLWithString:absolutePath relativeToURL:self.wordPressComRESTAPI.baseURL];
    return [url absoluteString];
}


#pragma mark - Private Methods

/**
 Fetches the posts from the specified remote endpoint

 @param params A dictionary of parameters supported by the endpoint. Params are converted to the request's query string.
 @param success block called on a successful fetch.
 @param failure block called if there is any error. `error` can be any underlying network error.
 */
- (void)fetchPostsFromEndpoint:(NSURL *)endpoint
                    withParameters:(NSDictionary *)params
                           success:(void (^)(NSArray<RemoteReaderPost *> *posts, NSString *algorithm))success
                           failure:(void (^)(NSError *))failure
{
    NSString *path = [endpoint absoluteString];
    [self.wordPressComRESTAPI get:path
           parameters:params
              success:^(id responseObject, NSHTTPURLResponse *httpResponse) {
                  if (!success) {
                      return;
                  }
                  if (![responseObject isKindOfClass:[NSDictionary class]]) {
                      if (failure) {
                          failure([NSError errorWithDomain:WordPressComRestApiErrorDomain code:-1 userInfo:nil]);
                      }
                      return;
                  }

                  dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_LOW, 0), ^{
                      // NOTE: Do all of this work on a background thread, then call success on the main thread.
                      // Do this to avoid any chance of blocking the UI while parsing.

                      // NOTE: If an offset param was specified sortRank will be derived
                      // from the offset + order of the results, ONLY if a `before` param
                      // was not specified.  If a `before` param exists we favor sorting by date.
                      BOOL rankByOffset = [params objectForKey:ParamKeyOffset] != nil && [params objectForKey:ParamKeyBefore] == nil;
                      __block CGFloat offset = [[params numberForKey:ParamKeyOffset] floatValue];
                      NSString *algorithm = [responseObject stringForKey:ParamsKeyAlgorithm];
                      NSArray *jsonPosts = [responseObject arrayForKey:PostRESTKeyPosts];
                      NSArray *posts = [jsonPosts wpkit_map:^id(NSDictionary *jsonPost) {
                          if (rankByOffset) {
                              RemoteReaderPost *post = [self formatPostDictionary:jsonPost offset:offset];
                              offset++;
                              return post;
                          }
                          return [[RemoteReaderPost alloc] initWithDictionary:jsonPost];
                      }];

                      // Now call success on the main thread.
                      dispatch_async(dispatch_get_main_queue(), ^{
                          success(posts, algorithm);
                      });
                  });

              } failure:^(NSError *error, NSHTTPURLResponse *httpResponse) {
                  if (failure) {
                      failure(error);
                  }
              }];
}

- (RemoteReaderPost *)formatPostDictionary:(NSDictionary *)dict offset:(CGFloat)offset
{
    RemoteReaderPost *post = [[RemoteReaderPost alloc] initWithDictionary:dict];
    // It's assumed that sortRank values are in descending order. Since
    // offsets are ascending, we store its negative to ensure we get a proper sort order.
    CGFloat adjustedOffset = -offset;
    post.sortRank = @(adjustedOffset);
    return post;
}

@end
