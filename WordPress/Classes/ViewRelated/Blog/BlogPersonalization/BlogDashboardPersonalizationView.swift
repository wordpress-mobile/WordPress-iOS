import SwiftUI

struct BlogDashboardPersonalizationView: View {
    @StateObject var viewModel: BlogDashboardPersonalizationViewModel

    @SwiftUI.Environment(\.presentationMode) var presentationMode

    var body: some View {
        List {
            Section(content: {
                ForEach(viewModel.cards, content: BlogDashboardPersonalizationCardCell.init)
            }, header: {
                Text(Strings.sectionHeader)
            }, footer: {
                Text(Strings.sectionFooter)
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

private struct BlogDashboardPersonalizationCardCell: View {
    @ObservedObject var viewModel: BlogDashboardPersonalizationCardCellViewModel

    var body: some View {
        Toggle(viewModel.title, isOn: $viewModel.isOn)
    }
}

private extension BlogDashboardPersonalizationView {
    struct Strings {
        static let title = NSLocalizedString("personalizeHome.title", value: "Personalize Home Tab", comment: "Page title")
        static let sectionHeader = NSLocalizedString("personalizeHome.cardsSectionHeader", value: "Add or hide cards", comment: "Section header")
        static let sectionFooter = NSLocalizedString("personalizeHome.cardsSectionFooter", value: "Cards may show different content depending on what's happening on your site. We're working on more cards and controls.", comment: "Section footer displayed below the list of toggles")
    }
}

#if DEBUG
struct BlogDashboardPersonalizationView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationView {
            BlogDashboardPersonalizationView(viewModel: .init(service: .init(repository: UserDefaults.standard, siteID: 1), quickStartType: .newSite))
        }
    }
}
#endif
