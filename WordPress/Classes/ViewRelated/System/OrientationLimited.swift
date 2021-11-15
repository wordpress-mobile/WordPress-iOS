import UIKit

// On rotation, WordPressAppDelegate will check if a VC is OrientationLimited.
// If so, it will use the VC's value for supportedInterfaceOrientations when
// returning a value from application(_:supportedInterfaceOrientationsFor:)
protocol OrientationLimited: UIViewController {}
