import SwiftUI

struct ReaderSubscriptionNotificationSettingsButton: View {
    let site: ReaderSiteTopic
    let status: ReaderSubscriptionNotificationsStatus
    @State var isShowingSettings = false

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
    }
}
