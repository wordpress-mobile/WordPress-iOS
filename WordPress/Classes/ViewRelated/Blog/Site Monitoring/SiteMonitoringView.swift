import SwiftUI
import UIKit

struct SiteMonitoringView: View {
    var body: some View {
        Text("Site Monitoring")
    }
}

final class SiteMonitoringViewController: UIHostingController<SiteMonitoringView> {

    init() {
        super.init(rootView: .init())
    }

    @MainActor required dynamic init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
