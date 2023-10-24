import SwiftUI

struct DomainListCard: View {

    struct ViewModel {

        let domainName: String
        let domainHeadline: String?
        let status: Status?
        let date: String?

        typealias Status = DomainsService.AllDomainsListItem.Status
        typealias StatusType = DomainsService.AllDomainsListItem.StatusType
    }

    private let domainInfo: ViewModel

    init(domainInfo: ViewModel) {
        self.domainInfo = domainInfo
    }

    var body: some View {
        textContainerVStack
            .padding(Length.Padding.double)
    }

    private var textContainerVStack: some View {
        VStack(alignment: .leading, spacing: Length.Padding.single) {
            domainText
            domainHeadline
            statusHStack
        }
    }

    private var domainText: some View {
        Text(domainInfo.domainName)
            .font(.callout)
            .foregroundColor(.primary)
    }

    private var domainHeadline: some View {
        Group {
            if let value = domainInfo.domainHeadline {
                Text(value)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            } else {
                EmptyView()
            }
        }
    }

    private var statusHStack: some View {
        HStack(spacing: Length.Padding.double) {
            statusText
            Spacer()
            expirationText
        }
    }

    private var statusText: some View {
        Group {
            if let status = domainInfo.status {
                HStack(spacing: Length.Padding.single) {
                    Circle()
                        .fill(status.type.indicatorColor)
                        .frame(
                            width: Length.Padding.single,
                            height: Length.Padding.single
                        )
                    Text(status.value)
                        .foregroundColor(status.type.textColor)
                        .font(.subheadline.weight(status.type.fontWeight))
                }
            } else {
                EmptyView()
            }
        }
    }

    private var expirationText: some View {
        Group {
            if let date = domainInfo.date {
                Text(date)
                    .font(.subheadline)
                    .foregroundColor(domainInfo.status?.type.expireTextColor ?? Color.DS.Foreground.secondary)
            } else {
                EmptyView()
            }
        }
    }
}

private extension DomainListCard.ViewModel.StatusType {

    var fontWeight: Font.Weight {
        switch self {
        case .error, .alert:
            return .bold
        default:
            return .regular
        }
    }

    var indicatorColor: Color {
        switch self {
        case .success, .premium:
            return Color.DS.Foreground.success
        case .warning:
            return Color.DS.Foreground.warning
        case .alert, .error:
            return Color.DS.Foreground.error
        case .neutral:
            return Color.DS.Foreground.secondary
        }
    }

    var textColor: Color {
        switch self {
        case .warning:
            return Color.DS.Foreground.warning
        case .alert, .error:
            return Color.DS.Foreground.error
        default:
            return Color.DS.Foreground.primary
        }
    }

    var expireTextColor: Color {
        switch self {
        case .warning:
            return Color.DS.Foreground.warning
        default:
            return Color.DS.Foreground.secondary
        }
    }
}


// MARK: - View Model

extension DomainListCard.ViewModel: MyDomainViewModel {

    private static let dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .none
        return formatter
    }()

    init(domain: DomainsService.AllDomainsListItem) {
        let domainHeadline: String? = {
            guard !domain.isDomainOnlySite else {
                return nil
            }
            return !domain.blogName.isEmpty ? domain.blogName : domain.siteSlug
        }()
        let date: String? = {
            guard let date = domain.expiryDate, domain.hasRegistration else {
                return nil
            }
            let expired = date < Date()
            let notice = expired ? Strings.expired : Strings.renews
            let formatted = Self.dateFormatter.string(from: date)
            return "\(notice) \(formatted)"
        }()
        self.init(
            domainName: domain.domain,
            domainHeadline: domainHeadline,
            status: domain.status,
            date: date
        )
    }

    private enum Strings {
        static let expired = NSLocalizedString(
            "domain.management.card.expired.label",
            value: "Expired",
            comment: "The expired label of the domain card in My Domains screen."
        )
        static let renews = NSLocalizedString(
            "domain.management.card.renews.label",
            value: "Renews",
            comment: "The renews label of the domain card in My Domains screen."
        )
    }
}


// MARK: - Previews

struct DomainListCard_Previews: PreviewProvider {
    static var previews: some View {
        ZStack {
            Color(.systemBackground)
            DomainListCard(
                domainInfo: .init(
                    domainName: "domain.cool.cool",
                    domainHeadline: "A Cool Website",
                    status: .init(value: "Active", type: .success),
                    date: "Expires Aug 15 2004"
                )
            )
        }
        .ignoresSafeArea()
        .environment(\.colorScheme, .light)
    }
}
