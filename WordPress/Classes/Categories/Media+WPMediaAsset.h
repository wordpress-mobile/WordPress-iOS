#import "Media.h"
#import <WPMediaPicker/WPMediaPicker.h>

/**
 Provides an implementation of Media conforming to the WPMediaAsset protocol.
 Note: Doesn't play nicely with Swift, see @property filename below.
 */
@interface Media (WPMediaAsset) <WPMediaAsset>

/** 
 Note: Redefine the filename property of Media to keep Swift happy.
 Otherwise, currently, Swift will only see the protocol method of filename() available,
 and not the (getter, setter) properity itself on Media.
 --Brent May/2017
 */
@property (nonatomic, strong, nullable) NSString *filename;

@end
