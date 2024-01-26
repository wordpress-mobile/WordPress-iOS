import SwiftUI
import UIKit

struct SiteMonitoringView: View {
    @StateObject var viewModel: SiteMonitoringViewModel

    var body: some View {
        main.navigationTitle(viewModel.selectedTab.title)
            .navigationBarTitleDisplayMode(.inline)
            .apply(addToolbarTitleMenu)
    }

    @ViewBuilder
    private var main: some View {
        switch viewModel.selectedTab {
        case .metrics:
            WebView(url: viewModel.metricsURL!)
        case .phpLogs:
            phpLogs
        case .webServerLogs:
            webServerLogs
        }
    }

    @ViewBuilder
    private var phpLogs: some View {
        List {
            Text("PHP Logs")
        }
    }

    @ViewBuilder
    private var webServerLogs: some View {
        List {
            Text("Web Server Logs")
        }
    }

    @ViewBuilder
    private func addToolbarTitleMenu<T: View>(_ view: T) -> some View {
        if #available(iOS 16, *) {
            view.toolbarTitleMenu {
                Picker("", selection: $viewModel.selectedTab) {
                    ForEach(SiteMonitoringTab.allCases) { tab in
                        Text(tab.title).tag(tab)
                    }
                }.pickerStyle(.inline)
            }
        } else {
            view
        }
    }
}

enum SiteMonitoringTab: Int, CaseIterable, Identifiable {
    case metrics
    case phpLogs
    case webServerLogs

    var id: Self { self }

    var title: String {
        switch self {
        case .metrics: return Strings.metrics
        case .phpLogs: return Strings.phpLogs
        case .webServerLogs: return Strings.webServerLogs
        }
    }
}

final class SiteMonitoringViewController: UIHostingController<SiteMonitoringView> {

    init(blog: Blog, selectedTab: SiteMonitoringTab? = nil) {
        super.init(rootView: .init(viewModel: SiteMonitoringViewModel(blog: blog, selectedTab: selectedTab)))
    }

    @MainActor required dynamic init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

final class SiteMonitoringViewModel: ObservableObject {
    private let blog: Blog

    @Published var selectedTab: SiteMonitoringTab = .metrics

    var metricsURL: URL? {
        guard let siteID = blog.dotComID as? Int else {
            return nil
        }
        return URL(string: "https://wordpress.com/site-monitoring/\(siteID)")
    }

    init(blog: Blog, selectedTab: SiteMonitoringTab? = nil) {
        self.blog = blog
        if let selectedTab {
            self.selectedTab = selectedTab
        }
    }
}

private enum Strings {
    static let metrics = NSLocalizedString("siteMonitoring.metrics", value: "Metrics", comment: "Title for metrics screen.")
    static let phpLogs = NSLocalizedString("siteMonitoring.phpLogs", value: "PHP Logs", comment: "Title for PHP logs screen.")
    static let webServerLogs = NSLocalizedString("siteMonitoring.metrics", value: "Web Server Logs", comment: "Title for web server log screen.")
}
