import SwiftUI

struct ReaderSubscriptionCell: View {
    let site: ReaderSiteTopic

    @State private var isShowingSettings = false

    @Environment(\.horizontalSizeClass) private var horizontalSizeClass

    var onDelete: (ReaderSiteTopic) -> Void

    private var details: String {
        let components = [
            horizontalSizeClass == .compact ? nil : URL(string: site.siteURL)?.host,
            Strings.numberOfSubscriptions(with: site.subscriberCount.intValue)
        ]
        return components.compactMap { $0 }.joined(separator: " · ")
    }

    var body: some View {
        HStack(spacing: 0) {
            HStack(spacing: 16) {
                let size = SiteIconViewModel.Size.regular
                SiteIconView(viewModel: .init(readerSiteTopic: site, size: size))
                    .frame(width: size.width, height: size.width)
                    .padding(.leading, 4)

                VStack(alignment: .leading, spacing: 3) {
                    HStack(alignment: .firstTextBaseline, spacing: 8) {
                        Text(site.title)
                            .font(.body.weight(.medium))
                    }
                    Text(details)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                .lineLimit(1)
            }

            Spacer()

            if let status = ReaderSubscriptionNotificationsStatus(site: site) {
                makeButtonNotificationSettings(with: status)
            }
            buttonMore
        }
    }

    private func makeButtonNotificationSettings(with status: ReaderSubscriptionNotificationsStatus) -> some View {
        Button {
            isShowingSettings = true
        } label: {
            Group {
                switch status {
                case .all:
                    Image(systemName: "bell.and.waves.left.and.right")
                        .foregroundStyle(AppColor.brand)
                case .personalized:
                    Image(systemName: "bell")
                        .foregroundStyle(AppColor.brand)
                case .none:
                    Image(systemName: "bell.slash")
                        .foregroundStyle(.secondary)
                        .opacity(0.6)
                }
            }
            .font(.subheadline)
            .frame(width: 34, alignment: .center)
            .padding(.trailing, 6)
        }
        .buttonStyle(.plain)
        .popover(isPresented: $isShowingSettings) { settings }
    }

    @ViewBuilder
    private var settings: some View {
        if horizontalSizeClass == .compact {
            ReaderSubscriptionNotificationSettingsView(siteID: site.siteID.intValue, isCompact: true)
                .presentationDetents([.medium, .large])
                .edgesIgnoringSafeArea(.all)
        } else {
            ReaderSubscriptionNotificationSettingsView(siteID: site.siteID.intValue)
        }
    }

    private var buttonMore: some View {
        Menu {
            if let siteURL = URL(string: site.siteURL) {
                ShareLink(item: siteURL)
            }
            Button(role: .destructive) {
                onDelete(site)
            } label: {
                Label(SharedStrings.Reader.unfollow, systemImage: "trash")
            }
        } label: {
            Image(systemName: "ellipsis")
                .foregroundStyle(.secondary)
        }
        .buttonStyle(.plain)
    }
}

private enum Strings {
    static let settings = NSLocalizedString("reader.subscriptions.settings", value: "Settings", comment: "Button title for managing subscription settings")

    static func numberOfSubscriptions(with count: Int) -> String {
        let singular = NSLocalizedString("reader.subscriptions.subscriptionsSingular", value: "%@ subscriber", comment: "Number of subscriptions on a site (singular)")
        let plural = NSLocalizedString("reader.subscriptions.subscriptionsPlural", value: "%@ subscribers", comment: "Number of subscriptions on a site (plural)")
        return String(format: count == 1 ? singular : plural, kFormatted(count))
    }

    private static func kFormatted(_ count: Int) -> String {
        count.formatted(.number.notation(.compactName))
    }
}
