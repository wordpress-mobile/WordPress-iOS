import Foundation
import SwiftUI

struct RegisterDomainSitePickerView: View {
    @StateObject var viewModel: BlogListViewModel
    let onSiteSelected: (Blog) -> Void

    var body: some View {
        BlogListView(viewModel: viewModel, onSiteSelected: onSiteSelected)
            .searchable(text: $viewModel.searchText)
    }
}
