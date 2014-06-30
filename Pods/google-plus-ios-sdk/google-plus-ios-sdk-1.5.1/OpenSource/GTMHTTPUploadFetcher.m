/* Copyright (c) 2010 Google Inc.
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *     http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */

//
//  GTMHTTPUploadFetcher.m
//

#if (!GDATA_REQUIRE_SERVICE_INCLUDES) || GDATA_INCLUDE_DOCS_SERVICE || \
  GDATA_INCLUDE_YOUTUBE_SERVICE || GDATA_INCLUDE_PHOTOS_SERVICE

#import "GTMHTTPUploadFetcher.h"

static NSUInteger const kQueryServerForOffset = NSUIntegerMax;

@interface GTMHTTPFetcher (ProtectedMethods)
@property (readwrite, retain) NSData *downloadedData;
- (void)releaseCallbacks;
- (void)stopFetchReleasingCallbacks:(BOOL)shouldReleaseCallbacks;
- (void)connectionDidFinishLoading:(NSURLConnection *)connection;
- (void)connection:(NSURLConnection *)connection didFailWithError:(NSError *)error;
@end

@interface GTMHTTPUploadFetcher ()
+ (GTMHTTPUploadFetcher *)uploadFetcherWithRequest:(NSURLRequest *)request
                                    fetcherService:(GTMHTTPFetcherService *)fetcherService;
- (void)setLocationURL:(NSURL *)location
            uploadData:(NSData *)data
      uploadFileHandle:(NSFileHandle *)fileHandle
        uploadMIMEType:(NSString *)uploadMIMEType
             chunkSize:(NSUInteger)chunkSize;

- (void)uploadNextChunkWithOffset:(NSUInteger)offset;
- (void)uploadNextChunkWithOffset:(NSUInteger)offset
                fetcherProperties:(NSMutableDictionary *)props;
- (void)destroyChunkFetcher;

- (void)handleResumeIncompleteStatusForChunkFetcher:(GTMHTTPFetcher *)chunkFetcher;

- (void)uploadFetcher:(GTMHTTPFetcher *)fetcher
         didSendBytes:(NSInteger)bytesSent
       totalBytesSent:(NSInteger)totalBytesSent
totalBytesExpectedToSend:(NSInteger)totalBytesExpected;

- (void)reportProgressManually;

- (NSUInteger)fullUploadLength;

-(BOOL)chunkFetcher:(GTMHTTPFetcher *)chunkFetcher
          willRetry:(BOOL)willRetry
           forError:(NSError *)error;

- (void)chunkFetcher:(GTMHTTPFetcher *)chunkFetcher
    finishedWithData:(NSData *)data
               error:(NSError *)error;
@end

@interface GTMHTTPUploadFetcher (PrivateMethods)
// private methods of the superclass
- (void)invokeSentDataCallback:(SEL)sel
                        target:(id)target
               didSendBodyData:(NSInteger)bytesWritten
             totalBytesWritten:(NSInteger)totalBytesWritten
     totalBytesExpectedToWrite:(NSInteger)totalBytesExpectedToWrite;

- (void)invokeFetchCallback:(SEL)sel
                     target:(id)target
                       data:(NSData *)data
                      error:(NSError *)error;

- (BOOL)invokeRetryCallback:(SEL)sel
                     target:(id)target
                  willRetry:(BOOL)willRetry
                      error:(NSError *)error;
@end

@implementation GTMHTTPUploadFetcher

+ (GTMHTTPUploadFetcher *)uploadFetcherWithRequest:(NSURLRequest *)request
                                        uploadData:(NSData *)data
                                    uploadMIMEType:(NSString *)uploadMIMEType
                                         chunkSize:(NSUInteger)chunkSize
                                    fetcherService:(GTMHTTPFetcherService *)fetcherService {
  GTMHTTPUploadFetcher *fetcher = [self uploadFetcherWithRequest:request
                                                  fetcherService:fetcherService];
  [fetcher setLocationURL:nil
               uploadData:data
         uploadFileHandle:nil
           uploadMIMEType:uploadMIMEType
                chunkSize:chunkSize];
  return fetcher;
}

+ (GTMHTTPUploadFetcher *)uploadFetcherWithRequest:(NSURLRequest *)request
                                  uploadFileHandle:(NSFileHandle *)fileHandle
                                    uploadMIMEType:(NSString *)uploadMIMEType
                                         chunkSize:(NSUInteger)chunkSize
                                    fetcherService:(GTMHTTPFetcherService *)fetcherService {
  GTMHTTPUploadFetcher *fetcher = [self uploadFetcherWithRequest:request
                                                  fetcherService:fetcherService];
  [fetcher setLocationURL:nil
               uploadData:nil
         uploadFileHandle:fileHandle
           uploadMIMEType:uploadMIMEType
                chunkSize:chunkSize];
  return fetcher;
}

+ (GTMHTTPUploadFetcher *)uploadFetcherWithLocation:(NSURL *)locationURL
                                   uploadFileHandle:(NSFileHandle *)fileHandle
                                     uploadMIMEType:(NSString *)uploadMIMEType
                                          chunkSize:(NSUInteger)chunkSize
                                     fetcherService:(GTMHTTPFetcherService *)fetcherService {
  GTMHTTPUploadFetcher *fetcher = [self uploadFetcherWithRequest:nil
                                                  fetcherService:fetcherService];
  [fetcher setLocationURL:locationURL
               uploadData:nil
         uploadFileHandle:fileHandle
           uploadMIMEType:uploadMIMEType
                chunkSize:chunkSize];
  return fetcher;
}

+ (GTMHTTPUploadFetcher *)uploadFetcherWithRequest:(NSURLRequest *)request
                                    fetcherService:(GTMHTTPFetcherService *)fetcherService {
  // Internal utility method for instantiating fetchers
  GTMHTTPUploadFetcher *fetcher;
  if (fetcherService) {
    fetcher = [fetcherService fetcherWithRequest:request
                                    fetcherClass:self];
  } else {
    fetcher = (GTMHTTPUploadFetcher *) [self fetcherWithRequest:request];
  }
  return fetcher;
}

- (void)setLocationURL:(NSURL *)location
            uploadData:(NSData *)data
      uploadFileHandle:(NSFileHandle *)fileHandle
        uploadMIMEType:(NSString *)uploadMIMEType
             chunkSize:(NSUInteger)chunkSize {
#if DEBUG
  NSAssert((data == nil) != (fileHandle == nil),
           @"upload data and fileHandle are mutually exclusive");
  NSAssert((self.mutableRequest == nil) != (location == nil),
           @"request and location are mutually exclusive");
  NSAssert(chunkSize > 0,@"chunk size is zero");
  NSAssert(chunkSize != NSUIntegerMax, @"chunk size is sentinel value");
#endif
  [self setLocationURL:location];
  [self setUploadData:data];
  [self setUploadFileHandle:fileHandle];
  [self setUploadMIMEType:uploadMIMEType];
  [self setChunkSize:chunkSize];

  // indicate that we've not yet determined the file handle's length
  uploadFileHandleLength_ = -1;

  // indicate that we've not yet determined the upload fetcher status
  statusCode_ = -1;

  // if this is restarting an upload begun by another fetcher,
  // the location is specified but the request is nil
  isRestartedUpload_ = (location != nil);

  // add our custom headers to the initial request indicating the data
  // type and total size to be delivered later in the chunk requests
  NSMutableURLRequest *mutableReq = [self mutableRequest];

  NSNumber *lengthNum = [NSNumber numberWithUnsignedInteger:[self fullUploadLength]];
  [mutableReq setValue:[lengthNum stringValue]
    forHTTPHeaderField:@"X-Upload-Content-Length"];

  [mutableReq setValue:uploadMIMEType
    forHTTPHeaderField:@"X-Upload-Content-Type"];
}

- (void)dealloc {
  [self releaseCallbacks];

  [chunkFetcher_ release];
  [locationURL_ release];
#if NS_BLOCKS_AVAILABLE
  [locationChangeBlock_ release];
#endif
  [uploadData_ release];
  [uploadFileHandle_ release];
  [uploadMIMEType_ release];
  [responseHeaders_ release];
  [super dealloc];
}

#pragma mark -

- (NSUInteger)fullUploadLength {
  if (uploadData_) {
    return [uploadData_ length];
  } else {
    if (uploadFileHandleLength_ == -1) {
      // first time through, seek to end to determine file length
      uploadFileHandleLength_ = (NSInteger) [uploadFileHandle_ seekToEndOfFile];
    }
    return (NSUInteger)uploadFileHandleLength_;
  }
}

- (NSData *)uploadSubdataWithOffset:(NSUInteger)offset
                             length:(NSUInteger)length {
  NSData *resultData = nil;

  if (uploadData_) {
    NSRange range = NSMakeRange(offset, length);
    resultData = [uploadData_ subdataWithRange:range];
  } else {
    @try {
      [uploadFileHandle_ seekToFileOffset:offset];
      resultData = [uploadFileHandle_ readDataOfLength:length];
    }
    @catch (NSException *exception) {
      NSLog(@"uploadFileHandle exception: %@", exception);
    }
  }

  return resultData;
}

#pragma mark Method overrides affecting the initial fetch only

- (BOOL)beginFetchWithDelegate:(id)delegate
             didFinishSelector:(SEL)finishedSEL {

  GTMAssertSelectorNilOrImplementedWithArgs(delegate, finishedSEL,
        @encode(GTMHTTPFetcher *), @encode(NSData *), @encode(NSError *), 0);

  // replace the finishedSEL with our own, since the initial finish callback
  // is just the beginning of the upload experience
  delegateFinishedSEL_ = finishedSEL;

  // if the client is running early 10.5 or iPhone 2, we may need to manually
  // send progress indication since NSURLConnection won't be calling back
  // to us during uploads
  needsManualProgress_ = ![GTMHTTPFetcher doesSupportSentDataCallback];

  initialBodyLength_ = [[self postData] length];

  if (isRestartedUpload_) {
    if (![self isPaused]) {
      if (delegate) {
        [self setDelegate:delegate];
        finishedSel_ = finishedSEL;
      }
      [self uploadNextChunkWithOffset:kQueryServerForOffset];
    }
    return YES;
  }

  // we don't need a finish selector since we're overriding
  // -connectionDidFinishLoading
  return [super beginFetchWithDelegate:delegate
                     didFinishSelector:NULL];
}

#if NS_BLOCKS_AVAILABLE
- (BOOL)beginFetchWithCompletionHandler:(void (^)(NSData *data, NSError *error))handler {
  // we don't want to call into the delegate's completion block immediately
  // after the finish of the initial connection (the delegate is called only
  // when uploading finishes), so we substitute our own completion block to be
  // called when the initial connection finishes
  void (^holdBlock)(NSData *data, NSError *error) = [[handler copy] autorelease];

  BOOL flag = [super beginFetchWithCompletionHandler:^(NSData *data, NSError *error) {
    // callback
    if (!isRestartedUpload_) {
      if (error == nil) {
        // swap in the actual completion block now, as it will be called later
        // when the upload chunks have completed
        [completionBlock_ autorelease];
        completionBlock_ = [holdBlock copy];
      } else {
        // pass the error on to the actual completion block
        holdBlock(nil, error);
      }
    } else {
      // If there was no initial request, then this fetch is resuming some
      // other uploadFetcher's initial request, and the superclass's connection
      // is never used, so at this point we call the user's actual completion
      // block.
      holdBlock(data, error);
    }
  }];
  return flag;
}
#endif

- (void)connection:(NSURLConnection *)connection
   didSendBodyData:(NSInteger)bytesWritten
 totalBytesWritten:(NSInteger)totalBytesWritten
totalBytesExpectedToWrite:(NSInteger)totalBytesExpectedToWrite {

  // ignore this callback if we're doing manual progress, mainly so that
  // we won't see duplicate progress callbacks when testing with
  // doesSupportSentDataCallback turned off
  if (needsManualProgress_) return;

  [self uploadFetcher:self
         didSendBytes:bytesWritten
       totalBytesSent:totalBytesWritten
totalBytesExpectedToSend:totalBytesExpectedToWrite];
}

- (BOOL)shouldReleaseCallbacksUponCompletion {
  // we don't want the superclass to release the delegate and callback
  // blocks once the initial fetch has finished
  //
  // this is invoked for only successful completion of the connection;
  // an error always will invoke and release the callbacks
  return NO;
}

- (void)invokeFinalCallbacksWithData:(NSData *)data
                               error:(NSError *)error
            shouldInvalidateLocation:(BOOL)shouldInvalidateLocation {
  // avoid issues due to being released indirectly by a callback
  [[self retain] autorelease];

  if (shouldInvalidateLocation) {
    [self setLocationURL:nil];
  }

  if (delegate_ && delegateFinishedSEL_) {
    [self invokeFetchCallback:delegateFinishedSEL_
                       target:delegate_
                         data:data
                        error:error];
  }

#if NS_BLOCKS_AVAILABLE
  if (completionBlock_) {
    completionBlock_(data, error);
  }

  [self setLocationChangeBlock:nil];
#endif

  [self releaseCallbacks];
}

- (void)connection:(NSURLConnection *)connection didFailWithError:(NSError *)error {
  // handle failure of the initial fetch as a simple fetcher failure, including
  // calling the delegate, and allowing retry to happen if appropriate
  SEL prevSel = finishedSel_;  // should be null
  finishedSel_ = delegateFinishedSEL_;
  [super connection:connection didFailWithError:error];

  // If retry later happens and succeeds, it shouldn't message the delegate
  // since we'll continue to chunk uploads.
  finishedSel_ = prevSel;
}

- (void)connectionDidFinishLoading:(NSURLConnection *)connection {

  // we land here once the initial fetch sending the initial POST body
  // has completed

  // let the superclass end its connection
  [super connectionDidFinishLoading:connection];

  NSInteger statusCode = [super statusCode];
  [self setStatusCode:statusCode];

  NSData *downloadedData = [self downloadedData];

  // we need to get the upload URL from the location header to continue
  NSDictionary *responseHeaders = [self responseHeaders];
  NSString *locationURLStr = [responseHeaders objectForKey:@"Location"];

  NSError *error = nil;

  if (statusCode >= 300) {
    if (retryTimer_) return;

    error = [NSError errorWithDomain:kGTMHTTPFetcherStatusDomain
                                code:statusCode
                            userInfo:nil];
  } else if ([downloadedData length] > 0) {
    // The initial response of the resumable upload protocol should have an
    // empty body
    //
    // This problem typically happens because the upload create/edit link URL was
    // not supplied with the request, and the server is thus expecting a non-
    // resumable request/response. It may also happen if an error JSON error body
    // is returned.
    //
    // We'll consider this status 501 Not Implemented rather than try to parse
    // the body to determine the actual error, but will provide the data
    // as userInfo for clients to inspect.
    NSDictionary *userInfo = [NSDictionary dictionaryWithObject:downloadedData
                                                         forKey:kGTMHTTPFetcherStatusDataKey];
    error = [NSError errorWithDomain:kGTMHTTPFetcherStatusDomain
                                code:501
                            userInfo:userInfo];
  } else {
#if DEBUG
    NSAssert([locationURLStr length] > 0, @"need upload location hdr");
#endif

    if ([locationURLStr length] == 0) {
      // we cannot continue since we do not know the location to use
      // as our upload destination
      //
      // we'll consider this status 501 Not Implemented
      error = [NSError errorWithDomain:kGTMHTTPFetcherStatusDomain
                                  code:501
                              userInfo:nil];
    }
  }

  if (error) {
    [self invokeFinalCallbacksWithData:downloadedData
                                 error:error
              shouldInvalidateLocation:YES];
    return;
  }

  [self setLocationURL:[NSURL URLWithString:locationURLStr]];

  // we've now sent all of the initial post body data, so we need to include
  // its size in future progress indicator callbacks
  initialBodySent_ = initialBodyLength_;

  if (needsManualProgress_) {
    [self reportProgressManually];
  }

  // just in case the user paused us during the initial fetch...
  if (![self isPaused]) {
    [self uploadNextChunkWithOffset:0];
  }
}

- (void)retryFetch {
  // Override the fetcher's retryFetch to retry with the saved delegateFinishedSEL_.
  [self stopFetchReleasingCallbacks:NO];

  [self beginFetchWithDelegate:delegate_
             didFinishSelector:delegateFinishedSEL_];
}

#pragma mark Chunk fetching methods

- (void)uploadNextChunkWithOffset:(NSUInteger)offset {
  // use the properties in each chunk fetcher
  NSMutableDictionary *props = [self properties];

  [self uploadNextChunkWithOffset:offset
                fetcherProperties:props];
}

- (void)uploadNextChunkWithOffset:(NSUInteger)offset
                fetcherProperties:(NSMutableDictionary *)props {
  // upload another chunk
  NSUInteger chunkSize = [self chunkSize];

  NSString *rangeStr, *lengthStr;
  NSData *chunkData;

  NSUInteger dataLen = [self fullUploadLength];

  if (offset == kQueryServerForOffset) {
    // resuming, so we'll initially send an empty data block and wait for the
    // server to tell us where the current offset really is
    chunkData = [NSData data];
    rangeStr = [NSString stringWithFormat:@"bytes */%llu",
                (unsigned long long)dataLen];
    lengthStr = @"0";
    offset = 0;
  } else {
    // uploading the next data chunk
    if (dataLen == 0) {
#if DEBUG
      NSAssert(offset == 0, @"offset %llu for empty data length", (unsigned long long)offset);
#endif
      chunkData = [NSData data];
      rangeStr = @"bytes */0";
      lengthStr = @"0";
    } else {
#if DEBUG
      NSAssert(offset < dataLen , @"offset %llu exceeds data length %llu",
               (unsigned long long)offset, (unsigned long long)dataLen);
#endif
      NSUInteger thisChunkSize = chunkSize;

      // if the chunk size is bigger than the remaining data, or else
      // it's close enough in size to the remaining data that we'd rather
      // avoid having a whole extra http fetch for the leftover bit, then make
      // this chunk size exactly match the remaining data size
      BOOL isChunkTooBig = (thisChunkSize + offset > dataLen);
      BOOL isChunkAlmostBigEnough = (dataLen - offset < thisChunkSize + 2500);

      if (isChunkTooBig || isChunkAlmostBigEnough) {
        thisChunkSize = dataLen - offset;
      }

      chunkData = [self uploadSubdataWithOffset:offset
                                         length:thisChunkSize];

      rangeStr = [NSString stringWithFormat:@"bytes %llu-%llu/%llu",
                  (unsigned long long)offset,
                  (unsigned long long)(offset + thisChunkSize - 1),
                  (unsigned long long)dataLen];
      lengthStr = [NSString stringWithFormat:@"%llu",
                   (unsigned long long)thisChunkSize];
    }
  }

  // track the current offset for progress reporting
  [self setCurrentOffset:offset];

  //
  // make the request for fetching
  //

  // the chunk upload URL requires no authentication header
  NSURL *locURL = [self locationURL];
  NSMutableURLRequest *chunkRequest = [NSMutableURLRequest requestWithURL:locURL];

  [chunkRequest setHTTPMethod:@"PUT"];

  // copy the user-agent from the original connection
  NSURLRequest *origRequest = [self mutableRequest];
  NSString *userAgent = [origRequest valueForHTTPHeaderField:@"User-Agent"];
  if ([userAgent length] > 0) {
    [chunkRequest setValue:userAgent forHTTPHeaderField:@"User-Agent"];
  }

  [chunkRequest setValue:rangeStr forHTTPHeaderField:@"Content-Range"];
  [chunkRequest setValue:lengthStr forHTTPHeaderField:@"Content-Length"];

  NSString *uploadMIMEType = [self uploadMIMEType];
  [chunkRequest setValue:uploadMIMEType forHTTPHeaderField:@"Content-Type"];

  //
  // make a new fetcher
  //
  GTMHTTPFetcher *chunkFetcher;

  chunkFetcher = [GTMHTTPFetcher fetcherWithRequest:chunkRequest];
  [chunkFetcher setDelegateQueue:[self delegateQueue]];
  [chunkFetcher setRunLoopModes:[self runLoopModes]];

  // if the upload fetcher has a comment, use the same comment for chunks
  NSString *baseComment = [self comment];
  if (baseComment) {
    [chunkFetcher setCommentWithFormat:@"%@ (%@)", baseComment, rangeStr];
  }

  // give the chunk fetcher the same properties as the previous chunk fetcher
  [chunkFetcher setProperties:props];

  // post the appropriate subset of the full data
  [chunkFetcher setPostData:chunkData];

  // copy other fetcher settings to the new fetcher
  [chunkFetcher setRetryEnabled:[self isRetryEnabled]];
  [chunkFetcher setMaxRetryInterval:[self maxRetryInterval]];
  [chunkFetcher setSentDataSelector:[self sentDataSelector]];
  [chunkFetcher setCookieStorageMethod:[self cookieStorageMethod]];

  if ([self isRetryEnabled]) {
    // we interpose our own retry method both so the sender is the upload
    // fetcher, and so we can change the request to ask the server to
    // tell us where to resume the chunk
    [chunkFetcher setRetrySelector:@selector(chunkFetcher:willRetry:forError:)];
  }

  [self setMutableRequest:chunkRequest];

  // when fetching chunks, a 308 status means "upload more chunks", but
  // success (200 or 201 status) and other failures are no different than
  // for the regular object fetchers
  BOOL didFetch = [chunkFetcher beginFetchWithDelegate:self
                                     didFinishSelector:@selector(chunkFetcher:finishedWithData:error:)];
  if (!didFetch) {
    // something went horribly wrong, like the chunk upload URL is invalid
    NSError *error = [NSError errorWithDomain:kGTMHTTPFetcherErrorDomain
                                         code:kGTMHTTPFetcherErrorChunkUploadFailed
                                     userInfo:nil];

    [self invokeFinalCallbacksWithData:nil
                                 error:error
              shouldInvalidateLocation:YES];
    [self destroyChunkFetcher];
  } else {
    // hang on to the fetcher in case we need to cancel it
    [self setChunkFetcher:chunkFetcher];
  }
}

- (void)reportProgressManually {
  // reportProgressManually should be called only when there's no
  // NSURLConnection support for sent data callbacks

  // the user wants upload progress, and there's no support in NSURLConnection
  // for it, so we'll provide it here after each chunk
  //
  // the progress will be based on the uploadData and currentOffset,
  // so we can pass zeros
  [self uploadFetcher:self
         didSendBytes:0
       totalBytesSent:0
totalBytesExpectedToSend:0];
}

- (void)chunkFetcher:(GTMHTTPFetcher *)chunkFetcher finishedWithData:(NSData *)data error:(NSError *)error {
  [self setStatusCode:[chunkFetcher statusCode]];
  [self setResponseHeaders:[chunkFetcher responseHeaders]];

  if (error) {
    int status = (int)[error code];

    // status 308 is "resume incomplete", meaning we should get the offset
    // from the Range header and upload the next chunk
    //
    // any other status really is an error
    if (status == 308) {
      [self handleResumeIncompleteStatusForChunkFetcher:chunkFetcher];
      return;
    } else {
      // some unexpected status has occurred; handle it as we would a regular
      // object fetcher failure
      error = [NSError errorWithDomain:kGTMHTTPFetcherStatusDomain
                                  code:status
                              userInfo:nil];
      [self invokeFinalCallbacksWithData:data
                                   error:error
                shouldInvalidateLocation:NO];
      [self destroyChunkFetcher];
      return;
    }
  } else {
    // the final chunk has uploaded successfully
  #if DEBUG
    NSInteger status = [chunkFetcher statusCode];
    NSAssert1(status == 200 || status == 201,
              @"unexpected chunks status %d", (int)status);
  #endif

    // take the chunk fetcher's data as our own
    self.downloadedData = data;

    if (needsManualProgress_) {
      // do a final upload progress report, indicating all of the chunk data
      // has been sent
      NSUInteger fullDataLength = [self fullUploadLength] + initialBodyLength_;
      [self setCurrentOffset:fullDataLength];

      [self reportProgressManually];
    }

    // we're done
    [self invokeFinalCallbacksWithData:data
                                 error:error
              shouldInvalidateLocation:YES];

    [self destroyChunkFetcher];
  }
}

- (void)handleResumeIncompleteStatusForChunkFetcher:(GTMHTTPFetcher *)chunkFetcher {

  NSDictionary *responseHeaders = [chunkFetcher responseHeaders];

  // parse the Range header from the server, since that tells us where we really
  // want the next chunk to begin.
  //
  // lack of a range header means the server has no bytes stored for this upload
  NSString *rangeStr = [responseHeaders objectForKey:@"Range"];
  NSUInteger newOffset = 0;
  if (rangeStr != nil) {
    // parse a content-range, like "bytes=0-999", to find where our new
    // offset for uploading from the data really is (at the end of the
    // range)
    NSScanner *scanner = [NSScanner scannerWithString:rangeStr];
    long long rangeStart = 0, rangeEnd = 0;
    if ([scanner scanString:@"bytes=" intoString:nil]
        && [scanner scanLongLong:&rangeStart]
        && [scanner scanString:@"-" intoString:nil]
        && [scanner scanLongLong:&rangeEnd]) {
      newOffset = (NSUInteger)rangeEnd + 1;
    }
  }

  [self setCurrentOffset:newOffset];

  if (needsManualProgress_) {
    [self reportProgressManually];
  }

  // if the response specifies a location, use that for future chunks
  NSString *locationURLStr = [responseHeaders objectForKey:@"Location"];
  if ([locationURLStr length] > 0) {
    [self setLocationURL:[NSURL URLWithString:locationURLStr]];
  }

  // we want to destroy this chunk fetcher before creating the next one, but
  // we want to pass on its properties
  NSMutableDictionary *props = [[[chunkFetcher properties] retain] autorelease];

  // we no longer need to be able to cancel this chunkFetcher
  [self destroyChunkFetcher];

  // We may in the future handle Retry-After and ETag headers per
  // http://code.google.com/p/gears/wiki/ResumableHttpRequestsProposal
  // but they are not currently sent by the upload server

  [self uploadNextChunkWithOffset:newOffset
                fetcherProperties:props];
}


-(BOOL)chunkFetcher:(GTMHTTPFetcher *)chunkFetcher willRetry:(BOOL)willRetry forError:(NSError *)error {
  if ([error code] == 308
      && [[error domain] isEqual:kGTMHTTPFetcherStatusDomain]) {
    // 308 is a normal chunk fethcher response, not an error
    // that needs to be retried
    return NO;
  }

  if (delegate_ && retrySel_) {

    // call the client with the upload fetcher as the sender (not the chunk
    // fetcher) to find out if it wants to retry
    willRetry = [self invokeRetryCallback:retrySel_
                                   target:delegate_
                                willRetry:willRetry
                                    error:error];
  }

#if NS_BLOCKS_AVAILABLE
  if (retryBlock_) {
    willRetry = retryBlock_(willRetry, error);
  }
#endif

  if (willRetry) {
    // change the request being retried into a query to the server to
    // tell us where to resume
    NSMutableURLRequest *chunkRequest = [chunkFetcher mutableRequest];

    NSUInteger dataLen = [self fullUploadLength];
    NSString *rangeStr = [NSString stringWithFormat:@"bytes */%llu",
                          (unsigned long long)dataLen];

    [chunkRequest setValue:rangeStr forHTTPHeaderField:@"Content-Range"];
    [chunkRequest setValue:@"0" forHTTPHeaderField:@"Content-Length"];
    [chunkFetcher setPostData:[NSData data]];

    // we don't know what our actual offset is anymore, but the server
    // will tell us
    [self setCurrentOffset:0];
  }

  return willRetry;
}

- (void)destroyChunkFetcher {
  [chunkFetcher_ stopFetching];
  [chunkFetcher_ setProperties:nil];
  [chunkFetcher_ autorelease];
  chunkFetcher_ = nil;
}

// the chunk fetchers use this as their sentData method
- (void)uploadFetcher:(GTMHTTPFetcher *)chunkFetcher
         didSendBytes:(NSInteger)bytesSent
       totalBytesSent:(NSInteger)totalBytesSent
totalBytesExpectedToSend:(NSInteger)totalBytesExpected {
  // the actual total bytes sent include the initial XML sent, plus the
  // offset into the batched data prior to this fetcher
  totalBytesSent += initialBodySent_ + currentOffset_;

  // the total bytes expected include the initial XML and the full chunked
  // data, independent of how big this fetcher's chunk is
  totalBytesExpected = (NSInteger)(initialBodyLength_ + [self fullUploadLength]);

  if (delegate_ && delegateSentDataSEL_) {
    // ensure the chunk fetcher survives the callback in case the user pauses
    // the upload process
    [[chunkFetcher retain] autorelease];

    [self invokeSentDataCallback:delegateSentDataSEL_
                          target:delegate_
                 didSendBodyData:bytesSent
               totalBytesWritten:totalBytesSent
       totalBytesExpectedToWrite:totalBytesExpected];
  }

#if NS_BLOCKS_AVAILABLE
  if (sentDataBlock_) {
    sentDataBlock_(bytesSent, totalBytesSent, totalBytesExpected);
  }
#endif
}

#pragma mark -

- (BOOL)isPaused {
  return isPaused_;
}

- (void)pauseFetching {
  isPaused_ = YES;

  // pausing just means stopping the current chunk from uploading;
  // when we resume, the magic offset value will force us to send
  // a request to the server to figure out what bytes to start sending
  //
  // we won't try to cancel the initial data upload, but rather will look for
  // the magic offset value in -connectionDidFinishLoading before
  // creating first initial chunk fetcher, just in case the user
  // paused during the initial data upload
  [self destroyChunkFetcher];
}

- (void)resumeFetching {
  if (isPaused_) {
    isPaused_ = NO;

    [self uploadNextChunkWithOffset:kQueryServerForOffset];
  }
}

- (void)stopFetching {
  // overrides the superclass
  [self destroyChunkFetcher];

  [super stopFetching];
}

#pragma mark -

@synthesize uploadData = uploadData_,
            uploadFileHandle = uploadFileHandle_,
            uploadMIMEType = uploadMIMEType_,
            chunkSize = chunkSize_,
            currentOffset = currentOffset_,
            chunkFetcher = chunkFetcher_;

#if NS_BLOCKS_AVAILABLE
@synthesize locationChangeBlock = locationChangeBlock_;
#endif

@dynamic activeFetcher;
@dynamic responseHeaders;
@dynamic statusCode;

- (NSDictionary *)responseHeaders {
  // overrides the superclass

  // if asked for the fetcher's response, use the most recent fetcher
  if (responseHeaders_) {
    return responseHeaders_;
  } else {
    // no chunk fetcher yet completed, so return whatever we have from the
    // initial fetch
    return [super responseHeaders];
  }
}

- (void)setResponseHeaders:(NSDictionary *)dict {
  [responseHeaders_ autorelease];
  responseHeaders_ = [dict retain];
}

- (NSInteger)statusCode {
  if (statusCode_ != -1) {
    // overrides the superclass to indicate status appropriate to the initial
    // or latest chunk fetch
    return statusCode_;
  } else {
    return [super statusCode];
  }
}

- (void)setStatusCode:(NSInteger)val {
  statusCode_ = val;
}

- (SEL)sentDataSelector {
  // overrides the superclass
#if NS_BLOCKS_AVAILABLE
  BOOL hasSentDataBlock = (sentDataBlock_ != NULL);
#else
  BOOL hasSentDataBlock = NO;
#endif
  if ((delegateSentDataSEL_ || hasSentDataBlock) && !needsManualProgress_) {
    return @selector(uploadFetcher:didSendBytes:totalBytesSent:totalBytesExpectedToSend:);
  } else {
    return NULL;
  }
}

- (void)setSentDataSelector:(SEL)theSelector {
  // overrides the superclass
  delegateSentDataSEL_ = theSelector;
}

- (GTMHTTPFetcher *)activeFetcher {
  if (chunkFetcher_) {
    return chunkFetcher_;
  } else {
    return self;
  }
}

- (NSURL *)locationURL {
  return locationURL_;
}

- (void)setLocationURL:(NSURL *)url {
  if (url != locationURL_) {
    [locationURL_ release];
    locationURL_ = [url retain];

#if NS_BLOCKS_AVAILABLE
    if (locationChangeBlock_) {
      locationChangeBlock_(url);
    }
#endif
  }
}
@end

#endif // #if !GDATA_REQUIRE_SERVICE_INCLUDES
