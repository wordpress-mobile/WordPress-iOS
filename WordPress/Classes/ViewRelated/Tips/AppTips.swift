import Foundation
import SwiftUI
import TipKit
import Combine

enum AppTips {
    static func initialize() {
        do {
            try Tips.configure()
        } catch {
            DDLogError("Error initializing tips: \(error)")
        }
    }

    struct SitePickerTip: Tip {
        let id = "site_picker_tip"

        var title: Text {
            Text(NSLocalizedString("tips.sitePickerTip.title", value: "Your Sites", comment: "Tip for site picker"))
        }

        var message: Text? {
            Text(NSLocalizedString("tips.sitePickerTip.message", value: "Tap to select a different site or create a new one", comment: "Tip for site picker"))
        }

        var image: Image? {
            Image(systemName: "rectangle.stack.badge.plus")
        }

        var options: [any TipOption] {
            MaxDisplayCount(1)
        }
    }

    struct SidebarTip: Tip {
        let id = "sidebar_tip"

        var title: Text {
            Text(NSLocalizedString("tips.sidebar.title", value: "Sidebar", comment: "Tip for sidebar"))
        }

        var message: Text? {
            Text(NSLocalizedString("tips.sidebar.message", value: "Swipe right to access your sites, Reader, notifications, and profile", comment: "Tip for sidebar"))
        }

        var image: Image? {
            Image(systemName: "sidebar.left")
        }

        var options: [any TipOption] {
            MaxDisplayCount(1)
        }
    }

    struct NewStatsTip: Tip {
        let id = "new_stats_tip_2"

        var title: Text {
            Text(NSLocalizedString("tips.newStats.title", value: "Try New Stats", comment: "Tip for new stats feature"))
        }

        var message: Text? {
            Text(NSLocalizedString("tips.newStats.message", value: "Experience new sleek and powerful stats. Switch back whenever you like.", comment: "Tip for new stats feature"))
        }

        var image: Image? {
            Image(systemName: "wand.and.sparkles.inverse")
        }

        var actions: [Action] {
            Action(id: "try-new-stats", title: NSLocalizedString(
                "tips.newStats.action",
                value: "Enable Now",
                comment: "Action button title to enable new stats from tip"
            ))
        }

        var options: [any TipOption] {
            MaxDisplayCount(1)
        }
    }

    struct StatsDateRangeTip: Tip {
        let id = "stats_date_range_tip"

        var title: Text {
            Text(NSLocalizedString("tips.statsDateRange.title", value: "Navigate Through Time", comment: "Title for stats date range control tip"))
        }

        var message: Text? {
            Text(NSLocalizedString("tips.statsDateRange.message", value: "Use the calendar to select days, weeks, months, years, or choose custom date ranges to view your stats.", comment: "Message explaining how to use the date range control"))
        }

        var image: Image? {
            Image(systemName: "calendar")
        }

        var options: [any TipOption] {
            MaxDisplayCount(1)
        }
    }
}

extension UIViewController {
    /// Registers a popover to be displayed for the given tip.
    func registerTipPopover(
        _ tip: some Tip,
        sourceItem: any UIPopoverPresentationControllerSourceItem,
        arrowDirection: UIPopoverArrowDirection? = nil,
        actionHandler: (@MainActor @Sendable (Tips.Action) -> Void)? = nil
    ) -> TipObserver? {
        let task = Task { @MainActor [weak self, weak sourceItem] in
            for await shouldDisplay in tip.shouldDisplayUpdates {
                if shouldDisplay, let sourceItem {
                    let popoverController = TipUIPopoverViewController(tip, sourceItem: sourceItem, actionHandler: actionHandler ?? { _ in })
                    popoverController.view.tintColor = .secondaryLabel
                    if let arrowDirection {
                        popoverController.popoverPresentationController?.permittedArrowDirections = arrowDirection
                    }
                    self?.present(popoverController, animated: true)
                } else {
                    if self?.presentedViewController is TipUIPopoverViewController {
                        self?.dismiss(animated: true)
                    }
                }
            }
        }
        return TipObserver {
            task.cancel()
        }
    }
}

typealias TipObserver = AnyCancellable
