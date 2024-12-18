import Foundation
import SwiftUI
import TipKit
import Combine

enum AppTips {
    static func initialize() {
        guard #available(iOS 17, *) else { return }
        do {
            try Tips.configure()
        } catch {
            DDLogError("Error initializing tips: \(error)")
        }
    }

    @available(iOS 17, *)
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

    @available(iOS 17, *)
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
}

extension UIViewController {
    /// Registers a popover to be displayed for the given tip.
    @available(iOS 17, *)
    func registerTipPopover(
        _ tip: some Tip,
        sourceItem: any UIPopoverPresentationControllerSourceItem,
        arrowDirection: UIPopoverArrowDirection? = nil,
        actionHandler: ((Tips.Action) -> Void)? = nil
    ) -> TipObserver? {
        let task = Task { @MainActor [weak self] in
            for await shouldDisplay in tip.shouldDisplayUpdates {
                if shouldDisplay {
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
