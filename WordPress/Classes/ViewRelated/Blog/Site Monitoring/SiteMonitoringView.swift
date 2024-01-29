import SwiftUI
import UIKit

@available(iOS 16, *)
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
            SiteMetricsView(blog: viewModel.blog)
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
        view.toolbarTitleMenu {
            Picker("", selection: $viewModel.selectedTab) {
                ForEach(SiteMonitoringTab.allCases) { tab in
                    Text(tab.title).tag(tab)
                }
            }.pickerStyle(.inline)
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

@available(iOS 16, *)
final class SiteMonitoringViewController: UIHostingController<SiteMonitoringView> {

    init(blog: Blog, selectedTab: SiteMonitoringTab? = nil) {
        super.init(rootView: .init(viewModel: SiteMonitoringViewModel(blog: blog, selectedTab: selectedTab)))
    }

    @MainActor required dynamic init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

final class SiteMonitoringViewModel: ObservableObject {
    let blog: Blog

    @Published var selectedTab: SiteMonitoringTab = .metrics

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
