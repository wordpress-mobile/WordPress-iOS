import SwiftUI

protocol ReaderNavigationMenuDelegate: AnyObject {
    func scrollViewDidScroll(_ scrollView: UIScrollView, velocity: CGPoint)
    func scrollViewWillEndDragging(_ scrollView: UIScrollView, withVelocity velocity: CGPoint, targetContentOffset: UnsafeMutablePointer<CGPoint>)
    func didTapDiscoverBlogs()
}

struct ReaderNavigationMenu: View {

    @ObservedObject var viewModel: ReaderTabViewModel

    var body: some View {
        HStack(spacing: 8.0) {
            ScrollView(.horizontal, showsIndicators: false) {
                HStack {
                    ReaderNavigationButton(viewModel: viewModel)
                    streamFilterView
                }
            }
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
        // If there's an active stream filter, show that instead.
        if let activeTopic = viewModel.activeStreamFilter?.topic {
            Button {
                viewModel.resetStreamFilter()
            } label: {
                streamFilterChip(title: activeTopic.title, isSelected: true)
            }
        } else {
            ForEach(viewModel.streamFilters) { filter in
                Button {
                    viewModel.didTapStreamFilterButton(with: filter)
                } label: {
                    streamFilterChip(title: filter.title)
                }
            }
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

    private var hasActiveFilter: Bool {
        return viewModel.activeStreamFilter != nil
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
