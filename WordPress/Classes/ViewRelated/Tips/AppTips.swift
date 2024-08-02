import Foundation
import SwiftUI
import TipKit

enum AppTips {
    static func initialize() {
        guard Feature.enabled(.tipKit), #available(iOS 17, *) else { return }
        do {
            try Tips.configure()
        } catch {
            DDLogError("Error initializing tips: \(error)")
        }
    }

    struct SitePickerTip: Tip {
        let id = "site_picker_tip"
        let title = Text(NSLocalizedString("tips.sitePickerTip.title", value: "Your Sites", comment: "Tip for site picker"))
        let message: Text? = Text(NSLocalizedString("tips.sitePickerTip.message", value: "Tap to select a different site or create a new one", comment: "Tip for site picker"))
        let image: Image? = Image(systemName: "rectangle.stack.badge.plus")
    }
}
