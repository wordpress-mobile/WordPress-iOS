import UIKit
import Combine
import WordPressShared
import WordPressUI

/// Whether a Reader screen shows the Notifications bell, and what tapping it does.
enum ReaderNotificationsBell: Equatable {
    /// The screen shows no bell.
    case hidden

    /// The bell opens the Notifications list in a popover.
    case popover

    /// The bell pushes the Notifications list onto the screen's navigation stack.
    case push

    /// - Parameters:
    ///   - showsPopoverInRegularWidth: Whether the screen is one that the split view shows as
    ///     Reader's main content on iPad. The Reader menu and Search sit in the supplementary
    ///     column, where the Jetpack app shows no bell either.
    ///   - horizontalSizeClass: The size class of the screen's layout. On iPad, this is
    ///     `.regular` for a screen in the expanded split view even when its column is compact.
    ///   - isPad: Whether the device is an iPad. Only an iPad shows Reader in the split view:
    ///     larger iPhones are regular width in landscape, with Reader still on a navigation stack.
    ///   - scope: The scope of the list the bell opens.
    init(
        showsPopoverInRegularWidth: Bool,
        horizontalSizeClass: UIUserInterfaceSizeClass,
        isPad: Bool = UIDevice.isPad(),
        scope: NotificationsListScope = .forAppNavigation()
    ) {
        switch horizontalSizeClass {
        case .regular where isPad || scope == .all:
            // The Jetpack app keeps the popover on larger iPhones in landscape: its Notifications
            // tab is another entrance to the list.
            self = showsPopoverInRegularWidth ? .popover : .hidden
        case .regular, .compact:
            // Reader is on a navigation stack. The bell is the only entrance to the Reader
            // notifications list, which the WordPress app shows because its Notifications tab
            // shows a poster.
            self = scope == .reader ? .push : .hidden
        case .unspecified:
            self = .hidden
        @unknown default:
            self = .hidden
        }
    }

    /// Opens the Notifications list from the bell of `viewController`.
    ///
    /// - Parameter sourceItem: The bell, which anchors the popover.
    @MainActor
    func open(from viewController: UIViewController, sourceItem: UIPopoverPresentationControllerSourceItem?) {
        switch self {
        case .hidden:
            wpAssertionFailure("tapped a hidden bell")
        case .popover:
            guard let sourceItem else {
                return wpAssertionFailure("a popover needs a source item")
            }
            NotificationsViewController.showInPopover(from: viewController, sourceItem: sourceItem)
        case .push:
            // A new list for each tap: it is released when it's popped, like other Reader screens.
            let notificationsVC = NotificationsViewController.makeForAppNavigation()
            viewController.navigationController?.pushViewController(notificationsVC, animated: true)
        }
    }

    static let accessibilityLabel = NSLocalizedString(
        "reader.notificationsBell.accessibilityLabel",
        value: "Notifications",
        comment: "Accessibility label for the bell button in Reader that opens the Notifications list"
    )
}

/// Makes the bell bar button item of a Reader screen and keeps its image current with the
/// account's activity indicator, if the list the bell opens tracks it.
@MainActor
final class ReaderNotificationsBarButton {
    private lazy var viewModel = NotificationsButtonViewModel(scope: .forAppNavigation())
    private var cancellable: AnyCancellable?

    /// Returns nil when `bell` is hidden. The previous item, if any, stops updating.
    func makeItem(for bell: ReaderNotificationsBell, target: AnyObject, action: Selector) -> UIBarButtonItem? {
        cancellable = nil
        guard bell != .hidden else {
            return nil
        }
        let item = UIBarButtonItem(image: nil, style: .plain, target: target, action: action)
        item.accessibilityLabel = ReaderNotificationsBell.accessibilityLabel
        cancellable = viewModel.$image.sink { item.image = $0 }
        return item
    }
}
