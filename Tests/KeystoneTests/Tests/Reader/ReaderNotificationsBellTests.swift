import Testing
import UIKit

@testable import WordPress

struct ReaderNotificationsBellTests {
    @Test(arguments: [NotificationsListScope.all, .reader])
    func iPadRegularWidthShowsThePopoverOnlyWhereTheScreenAllowsIt(scope: NotificationsListScope) {
        #expect(bell(showsPopoverInRegularWidth: true, .regular, isPad: true, scope: scope) == .popover)
        #expect(bell(showsPopoverInRegularWidth: false, .regular, isPad: true, scope: scope) == .hidden)
    }

    @Test(arguments: [false, true])
    func iPhoneRegularWidthPushesForTheReaderScope(showsPopoverInRegularWidth: Bool) {
        #expect(
            bell(showsPopoverInRegularWidth: showsPopoverInRegularWidth, .regular, isPad: false, scope: .reader)
                == .push
        )
    }

    @Test
    func iPhoneRegularWidthKeepsThePopoverForTheAllScope() {
        #expect(bell(showsPopoverInRegularWidth: true, .regular, isPad: false, scope: .all) == .popover)
        #expect(bell(showsPopoverInRegularWidth: false, .regular, isPad: false, scope: .all) == .hidden)
    }

    @Test(arguments: [false, true])
    func compactWidthPushesOnlyForTheReaderScope(isPad: Bool) {
        for showsPopoverInRegularWidth in [false, true] {
            #expect(
                bell(showsPopoverInRegularWidth: showsPopoverInRegularWidth, .compact, isPad: isPad, scope: .reader)
                    == .push
            )
            #expect(
                bell(showsPopoverInRegularWidth: showsPopoverInRegularWidth, .compact, isPad: isPad, scope: .all)
                    == .hidden
            )
        }
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

    @Test
    @MainActor
    func streamItemTagsDifferFromTheDefaultTag() {
        let defaultTag = UIBarButtonItem().tag
        for tag in ReaderStreamViewController.NavigationItemTag.allCases {
            #expect(tag.rawValue != defaultTag)
        }
    }

    private func bell(
        showsPopoverInRegularWidth: Bool,
        _ sizeClass: UIUserInterfaceSizeClass,
        isPad: Bool,
        scope: NotificationsListScope
    ) -> ReaderNotificationsBell {
        ReaderNotificationsBell(
            showsPopoverInRegularWidth: showsPopoverInRegularWidth,
            horizontalSizeClass: sizeClass,
            isPad: isPad,
            scope: scope
        )
    }
}
