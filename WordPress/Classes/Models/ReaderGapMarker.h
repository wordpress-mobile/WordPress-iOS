#import <CoreData/CoreData.h>
#ifdef KEYSTONE
#import "ReaderPost.h"
#else
@import WordPressData;
#endif

/**
 The ReaderGapMarker is a subclass of ReaderrPost whose purpose is to act as a 
 marker for gaps in synced content, but not show any content itself.
 */
@interface ReaderGapMarker : ReaderPost

@end
