#import <Foundation/Foundation.h>
#import <Lookback/LookbackRecordingOptions.h>

/*! 
 @header LookbackRecordingSession
 
 @abstract
 Represents a recording currently being in progress. You can use it to read
 the options that were used to start the recording, and to stop the recording.
 */
@interface LookbackRecordingSession : NSObject

- (instancetype)initWithOptions:(LookbackRecordingOptions*)options;

/*! The options used to start the recording. Modifying these options during recording leads to undefined behavior. */
@property (nonatomic, readonly, copy) LookbackRecordingOptions *options;

/*! Stop the recording. This is equivalent to saying [LookbackRecorder sharedRecorder].recording = NO;.*/
- (void)stopRecording;

/*! The name of the recording. The name can be modified by the user on the Preview screen, but may also be
    set programmatically using this property.
    
    @note 
    You can only set this property up until the point where "Upload" is pressed in Preview, or if preview is
    disabled, the property must be set before the recording stops. */
@property(nonatomic,copy) NSString *name;
@end
