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
                        .frame(maxHeight: .infinity)
                        .animation(.easeInOut, value: viewModel.selectedItem)
                    streamFilterView
                }
                .fixedSize(horizontal: false, vertical: true)
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
                    .padding(4.0)
            }
            .accessibilityLabel(Text(Strings.searchFilterAccessibilityLabel))
        }
    }

    @ViewBuilder
    var streamFilterView: some View {
        ForEach(filters) { filter in
            streamFilterChip(filter: filter, isSelected: hasActiveFilter)
                .transition(
                    .asymmetric(insertion: .slide, removal: .move(edge: .leading))
                    .combined(with: .opacity)
                )
        }
    }

    @ViewBuilder
    func streamFilterChip(filter: FilterProvider, isSelected: Bool) -> some View {
        HStack(alignment: .center, spacing: 8.0) {
            Button {
                viewModel.didTapStreamFilterButton(with: filter)
            } label: {
                Text(viewModel.activeStreamFilter?.topic.title ?? filter.title)
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .foregroundStyle(isSelected ? Colors.StreamFilter.selectedText : Colors.StreamFilter.text)
            }
            .accessibilityLabel(Text(filterAccessibilityLabel(for: filter)))
            .accessibilityHint(Text(isSelected ? Strings.activeFilterAccessibilityHint : String()))

            if isSelected {
                Button {
                    withAnimation(.easeInOut) {
                        viewModel.resetStreamFilter()
                    }
                } label: {
                    Image("reader-menu-close")
                        .frame(width: 24.0, height: 24.0)
                        .foregroundStyle(Colors.StreamFilter.selectedText)
                }
                .accessibilityLabel(Text(Strings.resetFilterAccessibilityLabel))
            }
        }
        .padding(.vertical, 6.0)
        .padding(.leading, 16.0)
        .padding(.trailing, isSelected ? 8.0 : 16.0)
        .frame(maxHeight: .infinity)
        .background(isSelected ? Colors.StreamFilter.selectedBackground : Colors.StreamFilter.background)
        .clipShape(Capsule())
    }

    private func filterAccessibilityLabel(for filter: FilterProvider) -> String {
        guard let activeFilter = viewModel.activeStreamFilter else {
            return filter.title
        }
        return String(format: Strings.activeFilterAccessibilityStringFormat, activeFilter.topic.title)
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

    struct Strings {
        static let activeFilterAccessibilityStringFormat = NSLocalizedString(
            "reader.navigation.menu.activeFilter.a11y.label",
            value: "Filtered by %1$@",
            comment: """
                Accessibility label for when the user has an active filter.
                This informs the user that the currently displayed stream is being filtered.
                """
        )

        static let activeFilterAccessibilityHint = NSLocalizedString(
            "reader.navigation.menu.filter.a11y.hint",
            value: "Opens the filter list",
            comment: """
                Accessibility hint that informs the user that the filter list will be opened when they interact
                with the filter chip button.
                """
        )

        static let resetFilterAccessibilityLabel = NSLocalizedString(
            "reader.navigation.menu.reset.a11y.label",
            value: "Reset",
            comment: "Accessibility label for the Close icon button, to reset the active filter."
        )

        static let searchFilterAccessibilityLabel = NSLocalizedString(
            "reader.navigation.menu.search.a11y.label",
            value: "Search",
            comment: "Accessibility label for the Search icon."
        )
    }
}
