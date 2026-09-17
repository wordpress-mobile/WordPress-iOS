import SwiftUI
import WordPressUI

struct BlogDetailsView: View {
    @State private var isShowingComments = false
    @ObservedObject var viewModel: BlogDetailsTableViewModel
    var headerViewController: UIViewController?
    let refresh: () async -> Void

    var body: some View {
        GeometryReader { geometry in
            if viewModel.isSplitViewDisplayed {
                menu(headerWidth: geometry.size.width).listStyle(.sidebar)
            } else {
                menu(headerWidth: geometry.size.width).listStyle(.insetGrouped)
            }
        }
        .refreshable { await refresh() }
        .accessibilityIdentifier("Blog Details Table")
        .onChange(of: viewModel.blog.objectID) { _, _ in
            isShowingComments = false
        }
    }

    private func menu(headerWidth: CGFloat) -> some View {
        List(selection: viewModel.isSplitViewDisplayed ? selection : nil) {
            if let headerViewController {
                Section {
                } header: {
                    BlogDetailsHeader(controller: headerViewController)
                        .frame(width: headerWidth)
                        .listRowInsets(EdgeInsets())
                }
            }
            ForEach(viewModel.sections.indices, id: \.self) { index in
                menuSection(viewModel.sections[index])
            }
        }
    }

    private func menuSection(_ section: BlogDetailsTableViewModel.Section) -> some View {
        Section {
            switch section.category {
            case .jetpackInstallCard, .migrationSuccess, .jetpackBrandingCard, .extensiveLogging, .xmlrpcDisabled:
                BlogDetailsCard(viewModel: viewModel, category: section.category)
                    .selectionDisabled()
                    .id(section.category)
                    .id(viewModel.blog.objectID)
                    .listRowInsets(EdgeInsets())
                    .listRowBackground(Color.clear)
                    .listRowSeparator(.hidden)
            default:
                ForEach(section.rows) { row in
                    menuButton(row)
                        .badge(row.detail.map { Text($0) })
                        .tag(row.id)
                        .selectionDisabled(!row.showsSelectionState)
                        .accessibilityIdentifier(row.accessibilityIdentifier ?? row.defaultAccessibilityIdentifier)
                        .accessibilityHint(row.accessibilityHint ?? "")
                }
            }
        } header: {
            if let title = section.title, !title.isEmpty {
                Text(title)
            }
        } footer: {
            if let footer = section.footerTitle, !footer.isEmpty {
                Text(footer)
            }
        }
    }

    private var selection: Binding<BlogDetailsTableViewModel.Row.ID?> {
        Binding(
            get: { viewModel.selectedRowID },
            set: { id in
                guard let row = viewModel.sections.lazy.flatMap(\.rows).first(where: { $0.id == id }) else { return }
                viewModel.select(row)
            }
        )
    }

    @ViewBuilder
    private func menuButton(_ row: BlogDetailsTableViewModel.Row) -> some View {
        if let destination = viewModel.commentsDestination(for: row) {
            NavigationLink(
                isActive: Binding(
                    get: { isShowingComments },
                    set: { isActive in
                        if isActive, !isShowingComments {
                            viewModel.trackCommentsOpened()
                        }
                        isShowingComments = isActive
                    }
                )
            ) {
                destination
                    .id(viewModel.blog.objectID)
                    .hidesAppTabBar()
            } label: {
                BlogDetailsMenuRow(row: row)
            }
        } else if viewModel.isSplitViewDisplayed, row.showsSelectionState {
            BlogDetailsMenuRow(row: row)
        } else {
            Button(role: row.kind == .removeSite ? .destructive : nil) {
                viewModel.select(row)
            } label: {
                if row.kind == .removeSite {
                    Text(row.title)
                        .frame(maxWidth: .infinity)
                        .contentShape(Rectangle())
                } else {
                    BlogDetailsMenuRow(
                        row: row,
                        showsDisclosureIndicator: row.showsDisclosureIndicator && !viewModel.isSplitViewDisplayed
                    )
                }
            }
        }
    }
}

private struct BlogDetailsMenuRow: View {
    let row: BlogDetailsTableViewModel.Row
    var showsDisclosureIndicator = false
    @ScaledMetric private var iconSize = 24.0

    var body: some View {
        HStack {
            Label {
                Text(row.title)
                    .foregroundStyle(Color(uiColor: .label))
            } icon: {
                if let image = row.image {
                    Image(uiImage: image)
                        .resizable()
                        .scaledToFit()
                        .foregroundStyle(Color(uiColor: row.imageColor ?? .label))
                        .frame(width: iconSize, height: iconSize)
                        .accessibilityHidden(true)
                }
            }
            if let image = row.accessoryImage {
                Spacer()
                Image(uiImage: image)
                    .foregroundStyle(Color(uiColor: .tertiaryLabel))
                    .accessibilityHidden(true)
            } else if showsDisclosureIndicator {
                Spacer()
                Image(systemName: "chevron.right")
                    .font(.footnote.weight(.semibold))
                    .foregroundStyle(Color(uiColor: .tertiaryLabel))
                    .accessibilityHidden(true)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .contentShape(Rectangle())
        .accessibilityElement(children: .combine)
    }
}

private struct BlogDetailsHeader: UIViewControllerRepresentable {
    let controller: UIViewController

    func makeUIViewController(context: Context) -> UIViewController {
        let container = UIViewController()
        container.view.backgroundColor = .clear
        container.addChild(controller)
        container.view.addSubview(controller.view)
        controller.view.translatesAutoresizingMaskIntoConstraints = false
        container.view.pinSubviewToAllEdges(controller.view)
        controller.didMove(toParent: container)
        return container
    }

    func updateUIViewController(_ uiViewController: UIViewController, context: Context) {
        // The embedded header otherwise keeps its initial appearance when the color scheme changes.
        uiViewController.traitOverrides.userInterfaceStyle = context.environment.colorScheme == .dark ? .dark : .light
    }

    func sizeThatFits(_ proposal: ProposedViewSize, uiViewController: UIViewController, context: Context) -> CGSize? {
        guard let width = proposal.width else { return nil }
        return controller.view.systemLayoutSizeFitting(
            CGSize(width: width, height: UIView.layoutFittingCompressedSize.height),
            withHorizontalFittingPriority: .required,
            verticalFittingPriority: .fittingSizeLevel
        )
    }
}

private struct BlogDetailsCard: UIViewRepresentable {
    let viewModel: BlogDetailsTableViewModel
    let category: BlogDetailsTableViewModel.SectionCategory

    func makeUIView(context: Context) -> UITableViewCell {
        viewModel.makeCard(for: category)
    }

    func updateUIView(_ cell: UITableViewCell, context: Context) {}

    func sizeThatFits(_ proposal: ProposedViewSize, uiView: UITableViewCell, context: Context) -> CGSize? {
        guard let width = proposal.width else { return nil }
        return uiView.contentView.systemLayoutSizeFitting(
            CGSize(width: width, height: UIView.layoutFittingCompressedSize.height),
            withHorizontalFittingPriority: .required,
            verticalFittingPriority: .fittingSizeLevel
        )
    }
}

private extension BlogDetailsTableViewModel.Row {
    var defaultAccessibilityIdentifier: String {
        switch kind {
        case .removeSite: "BlogDetailsRemoveSiteCell"
        case .jetpackSettings, .siteSettings, .domain: "BlogDetailsSettingsCell"
        default: "BlogDetailsCell"
        }
    }
}
