import SwiftUI

struct BlogDashboardPersonalizationView: View {
    @StateObject var viewModel: BlogDashboardPersonalizationViewModel

    @SwiftUI.Environment(\.presentationMode) var presentationMode

    var body: some View {
        List {
            Section(content: {
                ForEach(viewModel.quickActions, content: BlogDashboardPersonalizationQuickActionCell.init)
            }, header: {
                Text(Strings.quickActionSectionHeader)
            })

            Section(content: {
                ForEach(viewModel.cards, content: BlogDashboardPersonalizationCardCell.init)
            }, header: {
                Text(Strings.cardSectionHeader)
            }, footer: {
                Text(Strings.cardSectionFooter)
            })
        }
        .listStyle(.insetGrouped)
        .navigationTitle(Strings.title)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) { closeButton }
        }
    }

    private var closeButton: some View {
        Button(action: { presentationMode.wrappedValue.dismiss() }) {
            Image(systemName: "xmark")
                .font(.body.weight(.medium))
                .foregroundColor(Color.primary)
        }
    }
}

private struct BlogDashboardPersonalizationQuickActionCell: View {
    @ObservedObject var viewModel: DashboardPersonalizationQuickActionViewModel

    var body: some View {
        Toggle(isOn: $viewModel.isOn) {
            Label(title: { Text(viewModel.title) }, icon: { Image(uiImage: viewModel.image ?? UIImage()) })
        }
    }
}

private struct BlogDashboardPersonalizationCardCell: View {
    @ObservedObject var viewModel: BlogDashboardPersonalizationCardCellViewModel

    var body: some View {
        Toggle(viewModel.title, isOn: $viewModel.isOn)
    }
}

private extension BlogDashboardPersonalizationView {
    struct Strings {
        static let title = NSLocalizedString("personalizeHome.title", value: "Personalize Home Tab", comment: "Page title")
        static let quickActionSectionHeader = NSLocalizedString("personalizeHome.shortcutsSectionHeader", value: "Show or hide shortcuts", comment: "Section header for shortcuts")
        static let cardSectionHeader = NSLocalizedString("personalizeHome.cardsSectionHeader", value: "Show or hide cards", comment: "Section header")
        static let cardSectionFooter = NSLocalizedString("personalizeHome.cardsSectionFooter", value: "Cards may show different content depending on what's happening on your site. We're working on more cards and controls.", comment: "Section footer displayed below the list of toggles")
    }
}
