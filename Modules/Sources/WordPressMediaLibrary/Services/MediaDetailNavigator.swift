import Foundation
import UIKit

/// App-injected UIKit navigation seam for the V2 Media Library detail flow.
/// The module wraps SwiftUI screens (`MediaDetailView`, `MediaFieldEditorView`)
/// in `UIHostingController` and asks the navigator to push them onto the
/// hosting controller's outer `UINavigationController`. The app-target
/// adapter resolves the current nav controller at push time.
///
/// Why: hosting `MediaLibraryView` inside an outer `UINavigationController`
/// AND wrapping its body in a SwiftUI `NavigationStack` produces a stacked
/// double nav bar. Bridging pushes through UIKit avoids the nested-stack
/// problem entirely.
@MainActor
public protocol MediaDetailNavigator: AnyObject {
    func push(_ viewController: UIViewController)
}
