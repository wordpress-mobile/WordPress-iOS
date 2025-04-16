import BuildSettingsKit
import UIKit
import WordPress

// The secrets _must_ be configured before the app launches.
//
// This is because `BuildSettings` are not propagated through the app via chain injection but accessed via a `static` `current` property for convenience.
// Also for convenience, we assume the secrets not to be nil at runtime, to avoid unwrapping values that we know must be there.
// Therefore, we need to make the secrets available to `BuildSettings` before the app starts.
BuildSettings.configure(secrets: ApiCredentials.toSecrets())

UIApplicationMain(
    CommandLine.argc,
    CommandLine.unsafeArgv,
    nil,
    NSStringFromClass(WordPressAppDelegate.self)
)
