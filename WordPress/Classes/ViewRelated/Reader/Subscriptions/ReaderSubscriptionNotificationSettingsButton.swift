import SwiftUI
import WordPressUI

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
                case .notify:
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
    /// Receive push notifications.
    case notify
    /// Receives emails notifications.
    case personalized
    /// Receives none.
    case none

    init(site: ReaderSiteTopic) {
        let notifications = site.postSubscription
        let emails = site.emailSubscription

        let sendNotifications = notifications?.sendPosts ?? false
        let sendEmails = (emails?.sendPosts ?? false) || (emails?.sendComments ?? false)

        if sendNotifications {
            self = .notify
        } else if sendEmails {
            self = .personalized
        } else {
            self = .none
        }
    }
}
