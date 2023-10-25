import SwiftUI

struct AllDomainsListCardView: View {

    private let viewModel: ViewModel

    init(viewModel: ViewModel) {
        self.viewModel = viewModel
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

    private var statusHStack: some View {
        HStack(spacing: Length.Padding.double) {
            statusText
            Spacer()
            expirationText
        }
    }

    private var statusText: some View {
        Group {
            if let status = viewModel.status {
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
            if let date = viewModel.expiryDate {
                Text(date)
                    .font(.subheadline)
                    .foregroundColor(viewModel.status?.type.expireTextColor ?? Color.DS.Foreground.secondary)
            } else {
                EmptyView()
            }
        }
    }

    typealias ViewModel = AllDomainsListItemViewModel
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

struct DomainListCard_Previews: PreviewProvider {
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
