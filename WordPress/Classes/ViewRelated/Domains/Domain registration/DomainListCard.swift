import SwiftUI

struct DomainListCard: View {
    struct DomainInfo {
        let domainName: String
        let domainHeadline: String
        let state: State
        let description: String?
        let date: String?
    }

    private let domainInfo: DomainInfo

    init(domainInfo: DomainInfo) {
        self.domainInfo = domainInfo
    }

    var body: some View {
        VStack {
            HStack(spacing: Length.Padding.double) {
                textContainerVStack
                chevronIcon
            }

            if let description = domainInfo.description {
                Divider()
                    .padding(.bottom, Length.Padding.double)
                descriptionText(description)
            }
        }
        .padding()
    }

    private var textContainerVStack: some View {
        VStack(alignment: .leading, spacing: Length.Padding.single) {
            domainText
            domainHeadline
                .padding(.bottom, Length.Padding.single)
            statusHStack
                .padding(.bottom, Length.Padding.double)
        }
    }

    private var domainText: some View {
        Text(domainInfo.domainName)
            .font(.callout)
            .foregroundColor(.primary)
    }

    private var domainHeadline: some View {
        Text(domainInfo.domainHeadline)
            .font(.subheadline)
            .foregroundColor(.secondary)
    }

    private var statusHStack: some View {
        HStack(spacing: Length.Padding.double) {
            statusText
            Spacer()
            expirationText
        }
    }

    private var statusText: some View {
        HStack(spacing: Length.Padding.single) {
            Circle()
                .fill(domainInfo.state.indicatorColor)
                .frame(
                    width: Length.Padding.single,
                    height: Length.Padding.single
                )
            Text(domainInfo.state.text)
                .foregroundColor(domainInfo.state.textColor)
                .font(.subheadline.weight(domainInfo.state.fontWeight))
        }
    }

    private var expirationText: some View {
        Text(domainInfo.date ?? "—")
            .font(.subheadline)
            .foregroundColor(domainInfo.state.expireTextColor)
    }

    private func descriptionText(_ description: String) -> some View {
        Text(description)
            .font(.subheadline)
            .foregroundColor(.secondary)
    }

    private var chevronIcon: some View {
        Image(systemName: "chevron.right")
            .foregroundColor(.DS.Foreground.secondary)
    }
}

extension DomainListCard {
    enum State {
        case completeSetup
        case failed
        case error
        case inProgress
        case actionRequired
        case expired
        case expiringSoon
        case renew
        case verifying
        case verifyEmail
        case active

        fileprivate var text: String {
            switch self {
            case .completeSetup:
                return NSLocalizedString(
                    "domain.status.complete.setup",
                    value: "Complete Setup",
                    comment: "Status of a domain in `Complete Setup` state"
                )
            case .failed:
                return NSLocalizedString(
                    "domain.status.failed",
                    value: "Failed",
                    comment: "Status of a domain in `Failed` state"
                )
            case .error:
                return NSLocalizedString(
                    "domain.status.error",
                    value: "Error",
                    comment: "Status of a domain in `Error` state"
                )
            case .inProgress:
                return NSLocalizedString(
                    "domain.status.in.progress",
                    value: "In Progress",
                    comment: "Status of a domain in `In Progress` state"
                )
            case .actionRequired:
                return NSLocalizedString(
                    "domain.status.action.required",
                    value: "Action Required",
                    comment: "Status of a domain in `Action Required` state"
                )
            case .expired:
                return NSLocalizedString(
                    "domain.status.expired",
                    value: "Expired",
                    comment: "Status of a domain in `Expired` state"
                )
            case .expiringSoon:
                return NSLocalizedString(
                    "domain.status.expiring.soon",
                    value: "Expiring Soon",
                    comment: "Status of a domain in `Expiring Soon` state"
                )
            case .renew:
                return NSLocalizedString(
                    "domain.status.renew",
                    value: "Renew",
                    comment: "Status of a domain in `Renew` state"
                )
            case .verifying:
                return NSLocalizedString(
                    "domain.status.verifying",
                    value: "Verifying",
                    comment: "Status of a domain in `Verifying` state"
                )
            case .verifyEmail:
                return NSLocalizedString(
                    "domain.status.verify.email",
                    value: "Verify Email",
                    comment: "Status of a domain in `Verify Email` state"
                )
            case .active:
                return NSLocalizedString(
                    "domain.status.active",
                    value: "Active",
                    comment: "Status of a domain in `Active` state"
                )
            }
        }

        fileprivate var fontWeight: Font.Weight {
            switch self {
            case .error,
                    .expired,
                    .expiringSoon:
                return .bold
            default:
                return .regular
            }
        }

        fileprivate var indicatorColor: Color {
            switch self {
            case .active:
                return Color.DS.Foreground.success
            case .completeSetup,
                    .actionRequired,
                    .expired,
                    .expiringSoon:
                return Color.DS.Foreground.warning
            case .failed,
                    .error:
                return Color.DS.Foreground.error
            case .inProgress,
                    .renew,
                    .verifying,
                    .verifyEmail:
                return Color.DS.Foreground.secondary
            }
        }

        fileprivate var textColor: Color {
            switch self {
            case .completeSetup,
                    .actionRequired,
                    .expired,
                    .expiringSoon:
                return Color.DS.Foreground.warning
            case .failed,
                    .error:
                return Color.DS.Foreground.error
            case .inProgress,
                    .renew,
                    .verifying,
                    .verifyEmail,
                    .active:
                return Color.DS.Foreground.primary
            }
        }

        fileprivate var expireTextColor: Color {
            switch self {
            case .expired:
                return Color.DS.Foreground.warning
            default:
                return Color.DS.Foreground.secondary
            }
        }
    }
}

struct DomainListCard_Previews: PreviewProvider {
    static var previews: some View {
        ZStack {
            Color(.systemBackground)
            DomainListCard(
                domainInfo: .init(
                    domainName: "domain.cool.cool",
                    domainHeadline: "A Cool Website",
                    state: .actionRequired,
                    description: "This domain requires explicit user consent to complete the registration. Please check the email sent for further details.",
                    date: "Expires Aug 15 2004"
                )
            )
        }
        .ignoresSafeArea()
        .environment(\.colorScheme, .light)
    }
}
