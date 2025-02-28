import SwiftUI

struct ReaderSubscriptionNotificationSettingsButton: View {
    @ObservedObject var site: ReaderSiteTopic

    @State private var isShowingSettings = false
    @State private var status: ReaderSubscriptionNotificationsStatus = .none

    var body: some View {
        Button {
            isShowingSettings = true
        } label: {
            Group {
                switch status {
                case .all:
                    Image(systemName: "bell.and.waves.left.and.right")
                        .foregroundStyle(AppColor.primary)
                case .personalized:
                    Image(systemName: "bell")
                        .foregroundStyle(AppColor.primary)
                case .none:
                    Image(systemName: "bell.slash")
                        .foregroundStyle(.secondary)
                        .opacity(0.6)
                }
            }
            .font(.subheadline)
            .frame(width: 34, alignment: .center)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .sheet(isPresented: $isShowingSettings) {
            ReaderSubscriptionNotificationSettingsView(siteID: site.siteID.intValue)
                .presentationDetents([.medium, .large])
                .edgesIgnoringSafeArea(.bottom)
        }
        .onReceive(site.emailSubscription?.objectWillChange ?? .init()) {
            refresh()
        }
        .onReceive(site.postSubscription?.objectWillChange ?? .init()) {
            refresh()
        }
        .onAppear { refresh() }
    }

    private func refresh() {
        status = ReaderSubscriptionNotificationsStatus(site: site)
    }
}

private enum ReaderSubscriptionNotificationsStatus {
    /// Receives both posts and notifications
    case all
    /// Receives some notifications
    case personalized
    /// Receives none
    case none

    init(site: ReaderSiteTopic) {
        let posts = site.postSubscription
        let emails = site.emailSubscription

        let sendPosts = (posts?.sendPosts ?? false) || (emails?.sendPosts ?? false)
        let sendComments = emails?.sendComments ?? false
        if sendPosts && sendComments {
            self = .all
        } else if sendPosts || sendComments {
            self = .personalized
        } else {
            self = .none
        }
    }
}
