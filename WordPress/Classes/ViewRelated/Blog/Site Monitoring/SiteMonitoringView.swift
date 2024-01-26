import SwiftUI
import UIKit

struct SiteMonitoringView: View {
    var body: some View {
        Text("Site Monitoring")
    }
}

enum SiteMonitoringTab: Int {
    case metrics
    case phpLogs
    case webServerLogs
}

final class SiteMonitoringViewController: UIHostingController<SiteMonitoringView> {

    init(selectedTab: SiteMonitoringTab? = nil) {
        // TODO: Open the selected tab if passed
        super.init(rootView: .init())
    }

    @MainActor required dynamic init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
