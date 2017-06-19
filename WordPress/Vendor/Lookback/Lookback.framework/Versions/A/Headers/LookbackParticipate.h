#import <UIKit/UIKit.h>
@protocol LookbackParticipateDelegate;

NS_ASSUME_NONNULL_BEGIN

/*! @header LookbackParticipate.h
 
    @abstract
    Public interface for Lookback Participate, the friendly UX for guiding test particioants
    through a research session, be it live, self-guided or in person.
*/


/*! @class LookbackParticipate

    @abstract
    By setting up Participate for your app, you prepare your app for receiving "Participate URLs",
    and allows it to be used in UX research. Participate is a UI layer on top of of the `LookbackRecorder`,
    so that Lookback can take care of the full research flow for you.
    
    The Participate flow is completely self contained, so once implemented, you do not need to
    use the `LookbackRecorder` or any other SDK API.
    
    @discussion
    
    # INSTALLATION GUIDE
    
    To use Participate inside your app:
    
    1. Add Lookback as a CocoaPod dependency to your project (or download and link the .framework and resource
       bundle manually).
    2. At lookback.io/dashboard, create a new iOS project, then configure it for "iOS app".
    3. Create a new app, and copy the "URL prefix".
    4. In Xcode > Your project > Your app target > Info > URL Types, create a new URL type, and paste the
       "URL prefix" into both "identifier" and "URL Schemes".
    5. In your app delegate, create an instance variable for a LookbackParticipate instance.
    6. from application:didFinishLaunchingWithOptions:, create the instance, and call
       setupFromDidFinishLaunchingWithApplicationWindow: with your main application window.
    7. In your app delegate, implement application:openURL:options: and application:continueUserActivity:restorationHandler:,
       and just forward the calls to LookbackParticipate.
       
    You're done! Now whenever a user taps a Participate link targeted for your app, your app will launch and a research
    session will be started.
    
    # EXAMPLE INTEGRATION
    
    <code><pre>
    class AppDelegate: UIResponder, UIApplicationDelegate {
        var window: UIWindow?
        var participate: LookbackParticipate!
        
        func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplicationLaunchOptionsKey: Any]?) -> Bool
        {
            participate = LookbackParticipate()
            participate.setup(withApplicationWindow: self.window!)
            return true
        }

        func application(_ app: UIApplication, open url: URL, options: [UIApplicationOpenURLOptionsKey : Any] = [:]) -> Bool
        {
            return participate.startParticipation(from: url)
        }
    }
    </pre></code>
    
    # USAGE FLOW
 
    The usage flow, all the way from integration to completed research using the Participate SDK
    is as follows:
 
    1. You integrate the Participate SDK into your app by calling the public API of this class
       from your app delegate and configuring your info.plist. This has no visible effect on your app,
       but prepares it for future research.
    2. You distribute your app through AppStore, TestFlight or other means to your potential testers.
    3. You or your UX researcher creates a project on the Lookback Dashboard https://lookback.io/dashboard,
       and configures it to do research on your app.
    4. You send out a "Participate URL" to your test participant(s), probably over email
    5. Your participants tap the URL, which launches the Lookback web site with further instructions,
       telling them how to install your app and then start participating.
    6. When your participants tap the "Start participating!" button on that web site, your app is launched
       and the Participate UI is shown on top of your app, guiding your participants through the
       research flow. This flow might include setting up a live conversation, go through a fully guided
       remote self-test, or preparing for an in-house session.
    7. Your app and your user's interactions with it are recorded and/or live streamed to lookback.io, where your team
       can watch, communicate and collaborate around the collected video and research.
*/

@interface LookbackParticipate : NSObject

#pragma mark Required methods
/*!
    @method -setupWithApplicationWindow:
 
    @abstract
        Call from your app delegate's -[application:didFinishLaunchingWithOptions:] to enable Participate in your app.
    
    @discussion
        If there are pending actions from last time the app ran (such as finishing an upload), this method will display
        this UI modally in a separate window.
        
    @note Not calling this at app startup can lead to research not finishing or not uploading properly.
*/
- (void)setupWithApplicationWindow:(UIWindow*)applicationWindow;

/*!
    @method -startParticipationFromURL:
 
    @abstract
        This method inspects the incoming URL, and if it looks like a Participate URL (as vended by the lookback.io
        web dashboard, either a "live" or a "self-test" link), it presents UI in an overlay window to guide the user
        through a research session.
    
    @discussion
        Call this method from your application's -application:openURL:options:. You can send in any URL, and it will
        only return YES/true if it is a proper Participate URL. If you handle other types of URLs in your app, make
        sure to handle Participate URLs first, like so:
        
        <pre><code>
        func application(_ app: UIApplication, open url: URL, options: [UIApplicationOpenURLOptionsKey : Any] = [:]) -> Bool
        {
            if participate.startParticipation(from: url) {
                return true
            }
            
            ... application's own URL handling goes here
        }
        </code></pre>
*/
- (BOOL)startParticipationFromURL:(NSURL*)participateURL;

#pragma mark Optional functionality
/// @see LookbackParticipateDelegate
@property(nonatomic,weak) id<LookbackParticipateDelegate> delegate;

/// Whether the bubble that the user starts/stops the test with is on screen
@property(nonatomic) BOOL participateBubbleVisible;

/// Set this to completely cover your app with a screen explaining with Participate is and giving
/// instructions on how to use Participate. This screen completely takes over your app and there's no way to
/// cancel out of it except by opening a Participate link. Set this before calling
/// setupFromDidFinishLaunchingWithApplicationWindow:.
@property(nonatomic) BOOL takeoverWithIntro;

@end

@protocol LookbackParticipateDelegate <NSObject>
/// Session has started. Here's the optional URL to be tested. This URL is configured from the lookback dashboard project,
/// and can be anything. You could use an internal URL scheme to use this to load a specific view controller, or set up
/// your application in preparation for the test.
- (void)participate:(LookbackParticipate*)participate startedSessionWithURL:(nullable NSURL*)url;
@end

NS_ASSUME_NONNULL_END
