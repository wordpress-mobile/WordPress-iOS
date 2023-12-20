import SwiftUI

struct ReaderNavigationMenu: View {

    var viewModel: ReaderTabViewModel
    var selectedItem: ReaderTabItem

    var body: some View {
        HStack {
            ReaderNavigationButton(viewModel: viewModel, selectedItem: selectedItem)
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
        static let searchIcon: Color = Color(uiColor: UIColor(light: .black, dark: .white))
    }

}
