import SwiftUI

struct ReaderSubscriptionCell: View {
    let site: ReaderSiteTopic

    @State private var isEditingSettings = false

    var onDelete: (ReaderSiteTopic) -> Void

    private var details: String {
        let components = [
            URL(string: site.siteURL)?.host,
            Strings.numberOfSubscriptions(with: site.subscriberCount.intValue)
        ]
        return components.compactMap { $0 }.joined(separator: " · ")
    }

    var body: some View {
        HStack(spacing: 4) {
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

            buttonNotificationSettings
            buttonMore
        }
        .swipeActions(edge: .trailing) {
            Button(Strings.unfollow, role: .destructive) {
                onDelete(site)
            }
            .tint(Color.red)
        }
    }

    private var buttonNotificationSettings: some View {
        Button {
            isEditingSettings = true
        } label: {
            // TODO: (wpsidebar) implement
//            Group {
//                switch site.status {
//                case .all:
//                    Image(systemName: "bell.and.waves.left.and.right")
//                        .foregroundStyle(Color(.brand))
//                case .personalized:
//                    Image(systemName: "bell")
//                        .foregroundStyle(Color(.brand))
//                case .none:
//                    Image(systemName: "bell.slash")
//                        .foregroundStyle(.secondary)
//                        .opacity(0.6)
//                }
//            }
//            .font(.subheadline)
//            .frame(width: 44, alignment: .center)
        }
        .buttonStyle(.plain)
        .popover(isPresented: $isEditingSettings) {
            // TODO: (wpsidebar) implement
        }
    }

    private var buttonMore: some View {
        Menu {
            if let siteURL = URL(string: site.siteURL) {
                ShareLink(item: siteURL)
            }
            Button {
                // TODO: (wpsidebar) implement
            } label: {
                Label(Strings.settings, systemImage: "bell")
            }
            Button(role: .destructive) {
                onDelete(site)
            } label: {
                Label(Strings.unfollow, systemImage: "trash")
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
    static let unfollow = NSLocalizedString("reader.subscriptions.unfollow", value: "Unfollow", comment: "Destructive button title")

    static func numberOfSubscriptions(with count: Int) -> String {
        let singular = NSLocalizedString("reader.subscriptions.subscriptionsSingular", value: "%@ subscriber", comment: "Number of subscriptions on a site (singular)")
        let plural = NSLocalizedString("reader.subscriptions.subscriptionsPlural", value: "%@ subscribers", comment: "Number of subscriptions on a site (plural)")
        return String(format: count == 1 ? singular : plural, kFormatted(count))
    }

    private static func kFormatted(_ count: Int) -> String {
        count >= 1000 ? String(format: "%.0fK", Double(count) / 1000) : String(count)
    }
}
