import Foundation
import UIKit

let isRunningTests = NSClassFromString("XCTestCase") != nil
let appDelegateClass = isRunningTests ? "TestingAppDelegate" : NSStringFromClass(WordPressAppDelegate.self)

UIApplicationMain(
    CommandLine.argc,
    CommandLine.unsafeArgv,
    nil,
    appDelegateClass
)
