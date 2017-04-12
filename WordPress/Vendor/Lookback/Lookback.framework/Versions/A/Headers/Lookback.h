/*! @header Lookback.h
 *
 *  @abstract
 *  Public interface for Lookback, the UX testing tool that records your screen
 *  and camera and uploads it to http://lookback.io for further study.
 *
 *  @discussion
 *
 *  The Lookback for iOS SDK has two major APIs:
 *
 *  <ul>
 *  <li> The @ref LookbackParticipate  API enables fast, easy and friendly user experience research by guiding your research
 *       participants through the research flow, all the way from preparation, through testing, to upload and follow-ups.
 *       It is also the foundation for Lookback Live, where the research can be live streamed with direct face-to-face
 *       live streamed communication — like a video call, but with screen sharing on mobile.
 *  <li> The @ref LookbackRecorder  API gives you low level access to perform screen+face recording of your app and its users. Use this
 *       API if you want to build a customized recording experience, for example to perform diary studies, feedback
 *       collection, etc.
 *  </ul>
 *
 *  If possible, please consider using the Participate API, as it is much simpler, and we take care of all the UX
 *  and edge cases involved in performing user research.
 */

 #import <TargetConditionals.h>

// Participate API
#if TARGET_OS_IPHONE
#import <Lookback/LookbackParticipate.h>
#endif

// Recorder API
#import <Lookback/LookbackRecorder.h>
#if TARGET_OS_IPHONE
#import <Lookback/LookbackSettingsViewController.h>
#import <Lookback/LookbackRecordingsTableViewController.h>
#endif

// Deprecated APIs
#import <Lookback/LookbackDeprecated.h>

