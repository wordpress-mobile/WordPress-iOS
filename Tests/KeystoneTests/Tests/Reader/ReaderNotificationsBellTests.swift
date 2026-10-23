import Testing
import UIKit

@testable import WordPress

struct ReaderNotificationsBellTests {
    @Test(arguments: [NotificationsListScope.all, .reader])
    func regularWidthShowsThePopoverOnlyWhereTheScreenAllowsIt(scope: NotificationsListScope) {
        #expect(bell(showsPopoverInRegularWidth: true, .regular, scope: scope) == .popover)
        #expect(bell(showsPopoverInRegularWidth: false, .regular, scope: scope) == .hidden)
    }

    @Test(arguments: [false, true])
    func compactWidthPushesOnlyForTheReaderScope(showsPopoverInRegularWidth: Bool) {
        #expect(bell(showsPopoverInRegularWidth: showsPopoverInRegularWidth, .compact, scope: .reader) == .push)
        #expect(bell(showsPopoverInRegularWidth: showsPopoverInRegularWidth, .compact, scope: .all) == .hidden)
    }

    @Test
    @MainActor
    func barButtonItemIsAnnouncedAsNotifications() {
        let item = ReaderNotificationsBarButton()
            .makeItem(for: .push, target: NSObject(), action: #selector(NSObject.description))
        #expect(item?.accessibilityLabel == "Notifications")
    }

    @Test
    @MainActor
    func hiddenBellHasNoBarButtonItem() {
        let item = ReaderNotificationsBarButton()
            .makeItem(for: .hidden, target: NSObject(), action: #selector(NSObject.description))
        #expect(item == nil)
    }

    private func bell(
        showsPopoverInRegularWidth: Bool,
        _ sizeClass: UIUserInterfaceSizeClass,
        scope: NotificationsListScope
    ) -> ReaderNotificationsBell {
        ReaderNotificationsBell(
            showsPopoverInRegularWidth: showsPopoverInRegularWidth,
            horizontalSizeClass: sizeClass,
            scope: scope
        )
    }
}
