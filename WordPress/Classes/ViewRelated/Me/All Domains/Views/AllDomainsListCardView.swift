import SwiftUI
import DesignSystem

struct AllDomainsListCardView: View {

    // MARK: - Types

    struct ViewModel: Identifiable {
        let id = UUID()
        let name: String
        let description: String?
        let status: Status?
        let expiryDate: String?
        let isPrimary: Bool

        typealias Status = DomainsService.AllDomainsListItem.Status
        typealias StatusType = DomainsService.AllDomainsListItem.StatusType

        init(name: String, description: String?, status: Status?, expiryDate: String?, isPrimary: Bool = false) {
            self.name = name
            self.description = description
            self.status = status
            self.expiryDate = expiryDate
            self.isPrimary = isPrimary
        }
    }

    // MARK: - Properties

    private let viewModel: ViewModel
    private let padding: CGFloat

    // MARK: - Init

    init(viewModel: ViewModel, padding: CGFloat = Length.Padding.double) {
        self.viewModel = viewModel
        self.padding = padding
    }

    // MARK: - Views

    var body: some View {
        textContainerVStack
            .padding(padding)
    }

    private var textContainerVStack: some View {
        VStack(alignment: .leading, spacing: Length.Padding.single) {
            domainText
            domainHeadline
            primaryDomainLabel
            statusHStack
        }
    }

    private var domainText: some View {
        Text(viewModel.name)
            .font(.callout)
            .foregroundColor(.primary)
    }

    private var domainHeadline: some View {
        Group {
            if let value = viewModel.description {
                Text(value)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            } else {
                EmptyView()
            }
        }
    }

    private var primaryDomainLabel: some View {
        Group {
            if viewModel.isPrimary {
                PrimaryDomainView()
            } else {
                EmptyView()
            }
        }
    }

    private var statusHStack: some View {
        HStack(spacing: Length.Padding.double) {
            if let status = viewModel.status {
                statusText(status: status)
                Spacer()
            }
            expirationText
        }
    }

    private func statusText(status: DomainsService.AllDomainsListItem.Status) -> some View {
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
    }

    private var expirationText: some View {
        Group {
            if let date = viewModel.expiryDate {
                Text(date)
                    .font(.subheadline)
                    .foregroundColor(viewModel.status?.type.expireTextColor ?? Color.DS.Foreground.secondary)
            } else {
                EmptyView()
            }
        }
    }
}

private extension AllDomainsListCardView.ViewModel.StatusType {

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

// MARK: - Previews

struct AllDomainsListCardView_Previews: PreviewProvider {
    static var previews: some View {
        ZStack {
            Color(.systemBackground)
            AllDomainsListCardView(
                viewModel: .init(
                    name: "domain.cool.cool",
                    description: "A Cool Website",
                    status: .init(value: "Active", type: .success),
                    expiryDate: "Expires Aug 15 2004"
                )
            )
        }
        .ignoresSafeArea()
        .environment(\.colorScheme, .light)
    }
}
