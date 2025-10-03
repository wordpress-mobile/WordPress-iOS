import SwiftUI
import Support
import WordPressAPIInternal
import WebKit

struct RootSupportView: View {

    @EnvironmentObject
    var dataProvider: SupportDataProvider

    @State
    var dataLoadingError: Error? = nil

    @State
    var userIdentity: SupportUser? = nil

    @State
    var userIsEligibleForSupport: Bool = false

    var body: some View {
        List {
            Section("Support Profile") {
                if let identity = self.userIdentity {
                    ProfileView(user: identity)
                    .listRowBackground(Color.clear)
                    .listRowInsets(EdgeInsets(top: 0, leading: 0, bottom: 0, trailing: 0))
                } else {
                    Button(role: nil) {
                        debugPrint("Start WP.com login")
                    } label: {
                        Text("Sign in with WordPress.com")
                    }
                }
            }

            Section("How can we help?") {
                NavigationLink {
                    let url = URL(string: "https://apps.wordpress.com/support/")!
                    WebKitView(configuration: WebViewControllerConfiguration(url: url))
                } label: {
                    SubtitledListViewItem(
                        title: "Help Center",
                        subtitle: "Documentation and Tutorials to help you get started"
                    )
                }

                if let identity = self.userIdentity {
                    NavigationLink {
                        ConversationListView(currentUser: identity)
                            .environmentObject(self.dataProvider) // Required until SwiftUI owns the nav controller
                    } label: {
                        SubtitledListViewItem(
                            title: "Ask the bots",
                            subtitle: "Get quick answers to common questions"
                        )
                    }

                    NavigationLink {
                        SupportConversationListView(currentUser: identity)
                            .environmentObject(self.dataProvider) // Required until SwiftUI owns the nav controller
                    } label: {
                        SubtitledListViewItem(
                            title: "Ask the Happiness Engineers",
                            subtitle: "For your tough questions. We'll reply via email"
                        )
                    }
                }
            }

            Section("Diagnostics") {
                NavigationLink {
                    ActivityLogListView()
                        .environmentObject(self.dataProvider) // Required until SwiftUI owns the nav controller
                } label: {
                    SubtitledListViewItem(
                        title: "Application Logs",
                        subtitle: "Advanced tool to debug issues"
                    )
                }

                NavigationLink {
                    Text("Site Status Report")
                } label: {
                    SubtitledListViewItem(
                        title: "System Status Report",
                        subtitle: "Various system information about your site"
                    )
                }
            }
        }
        .navigationTitle("Support")
        .task {
            do {
                self.userIdentity = try await self.dataProvider.loadSupportIdentity()
            } catch {
                debugPrint(error.localizedDescription)
                self.dataLoadingError = error
            }
        }
    }
}

class RootSupportViewController: UIHostingController<AnyView> {

    private let dataProvider: SupportDataProvider

    @MainActor
    init(dataProvider: SupportDataProvider) {
        self.dataProvider = dataProvider
        let type = RootSupportView().environmentObject(self.dataProvider)
        super.init(rootView: AnyView(erasing: type))
    }

    @MainActor @preconcurrency required dynamic init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
//
//#Preview {
//    RootSupportView()
//}
