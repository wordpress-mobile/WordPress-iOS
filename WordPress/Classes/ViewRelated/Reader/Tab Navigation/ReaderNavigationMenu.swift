import SwiftUI

struct ReaderNavigationMenu: View {

    @ObservedObject var viewModel: ReaderTabViewModel
    @State var selectedItem: ReaderTabItem?

    var body: some View {
        HStack {
            // TODO: @dvdchr wrap in ScrollView.
            HStack {
                if let selectedItem {
                    ReaderNavigationButton(viewModel: viewModel, selectedItem: selectedItem)
                }

                // TODO: @dvdchr Replace with proper implementation
                ForEach(viewModel.streamFilters) { filter in
                    Text(filter.title).font(.subheadline)
                }
            }
            Spacer()
            Button {
                viewModel.navigateToSearch()
            } label: {
                Image(uiImage: .gridicon(.search).withRenderingMode(.alwaysTemplate))
                    .foregroundStyle(Colors.searchIcon)
            }
        }
    }

    struct Colors {
        static let searchIcon: Color = Color(uiColor: .text)
    }

}
