import SwiftUI

protocol ReaderNavigationMenuDelegate: AnyObject {
    func scrollViewDidScroll(_ scrollView: UIScrollView, velocity: CGPoint)
    func scrollViewWillEndDragging(_ scrollView: UIScrollView, withVelocity velocity: CGPoint, targetContentOffset: UnsafeMutablePointer<CGPoint>)
    func didTapDiscoverBlogs()
}

struct ReaderNavigationMenu: View {

    @ObservedObject var viewModel: ReaderTabViewModel

    private var filters: [FilterProvider] {
        if let activeStreamFilter = viewModel.activeStreamFilter,
           let activeFilterProvider = viewModel.streamFilters.first(where: { $0.id == activeStreamFilter.filterID }) {
            return [activeFilterProvider]
        }

        return viewModel.streamFilters
    }

    private var hasActiveFilter: Bool {
        return viewModel.activeStreamFilter != nil
    }

    var body: some View {
        HStack(spacing: 8.0) {
            ScrollView(.horizontal, showsIndicators: false) {
                HStack {
                    ReaderNavigationButton(viewModel: viewModel)
                    streamFilterView
                }
            }
            .animation(.easeInOut, value: filters)
            .mask({
                HStack(spacing: .zero) {
                    Rectangle().fill(.black)
                    LinearGradient(gradient: Gradient(colors: [.black, .clear]),
                                   startPoint: .leading,
                                   endPoint: .trailing)
                               .frame(width: 16)
                }
            })
            Spacer()
            Button {
                viewModel.navigateToSearch()
            } label: {
                Image(uiImage: .gridicon(.search)
                    .withRenderingMode(.alwaysTemplate))
                    .foregroundStyle(Colors.searchIcon)
            }
        }
    }

    @ViewBuilder
    var streamFilterView: some View {
        ForEach(filters) { filter in
            Button {
                if hasActiveFilter {
                    viewModel.resetStreamFilter()
                } else {
                    viewModel.didTapStreamFilterButton(with: filter)
                }
            } label: {
                streamFilterChip(title: viewModel.activeStreamFilter?.topic.title ?? filter.title, isSelected: hasActiveFilter)
            }
            .transition(
                .asymmetric(insertion: .slide, removal: .move(edge: .leading))
                .combined(with: .opacity)
            )
        }
    }

    @ViewBuilder
    func streamFilterChip(title: String, isSelected: Bool = false) -> some View {
        HStack(alignment: .center, spacing: 8.0) {
            Text(title)
                .font(.subheadline)
                .fontWeight(.semibold)
                .foregroundStyle(isSelected ? Colors.StreamFilter.selectedText : Colors.StreamFilter.text)

            if isSelected {
                Image("reader-menu-close")
                    .frame(width: 24.0, height: 24.0)
                    .foregroundStyle(Colors.StreamFilter.selectedText)
            }
        }
        // the inherent padding from the close image bumps the content height, so we'll need to reduce the padding
        // when the close button is shown.
        .padding(.vertical, isSelected ? 6.0 : 10.0)
        .padding(.leading, 16.0)
        .padding(.trailing, isSelected ? 8.0 : 16.0)
        .background(isSelected ? Colors.StreamFilter.selectedBackground : Colors.StreamFilter.background)
        .clipShape(Capsule())

    }

    struct Colors {
        static let searchIcon: Color = Color(uiColor: .text)

        struct StreamFilter {
            static let text = Color.primary
            static let background = Color(uiColor: .secondarySystemBackground)
            static let selectedText = Color(uiColor: .systemBackground)
            static let selectedBackground = Color.primary
        }
    }

}
