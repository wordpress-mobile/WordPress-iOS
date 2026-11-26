import UIKit
import Support

@MainActor
enum SupportHome {
    static func makeViewController() -> UIViewController {
        if RemoteFeatureFlag.newSupport.enabled() {
            RootSupportViewController(dataProvider: SupportDataProvider.shared)
        } else {
            SupportTableViewController(style: .insetGrouped)
        }
    }
}
