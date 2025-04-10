import BuildSettingsKit
import UIKit

// The secrets _must_ be configured before the app launches.
//
// This is because `BuildSettings` are not propagated through the app via chain injection but accessed via a `static` `current` property for convenience.
// Also for convenience, we assume the secrets not to be nil at runtime, to avoid unwrapping values that we know must be there.
// Therefore, we need to make the secrets available to `BuildSettings` before the app starts.
// FIXME: Sort ot Reader having its own ApiCredentials (soon to be BuildSecrets) instance
//BuildSettings.configure(secrets: ApiCredentials.toSecrets())
BuildSettings.configure(secrets: BuildSecrets.dummy)

UIApplicationMain(
    CommandLine.argc,
    CommandLine.unsafeArgv,
    nil,
    "WordPressAppDelegate"
)
