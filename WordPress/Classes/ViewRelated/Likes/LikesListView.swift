import SwiftUI
import WordPressData
import WordPressUI

/// Adaptive grid of users who liked a post, shared by the Stats and Reader likes screens.
///
/// A single `LazyVGrid` renders both layouts: one flexible column on the compact
/// horizontal size class (visually identical to the previous table) and an adaptive
/// multi-column grid on the regular size class (iPad full screen, split view, Stage Manager).
struct LikesListView: View {
    @ObservedObject var viewModel: LikesListViewModel

    /// Presents the tapped user's profile. The `CGRect` is the row's frame in global
    /// coordinates, used by the host to anchor the popover on iPad.
    let onSelectUser: (LikeUser, CGRect) -> Void

    @Environment(\.horizontalSizeClass) private var horizontalSizeClass

    /// Whether to render the adaptive multi-column grid (regular width) rather than the
    /// single full-width column (compact width) that mirrors the previous table.
    private var shouldShowGridView: Bool {
        horizontalSizeClass == .regular
    }

    private var columns: [GridItem] {
        if shouldShowGridView {
            return [GridItem(.adaptive(minimum: Metrics.minimumColumnWidth), spacing: 0)]
        }
        return [GridItem(.flexible(), spacing: 0)]
    }

    var body: some View {
        // A full-screen error only when there is nothing to show. With likes already
        // loaded, a failure renders as a footer instead so the list stays on screen.
        if let error = viewModel.error, viewModel.users.isEmpty {
            EmptyStateView {
                Label(error.title, systemImage: "exclamationmark.circle")
            } description: {
                error.subtitle.map { Text($0) }
            } actions: {
                Button(SharedStrings.Button.retry) {
                    viewModel.loadMore()
                }
            }
        } else {
            ScrollView {
                LazyVGrid(columns: columns, alignment: .leading, spacing: 0) {
                    ForEach(viewModel.users, id: \.objectID) { user in
                        LikeUserGridCell(
                            user: user,
                            showsDivider: !shouldShowGridView,
                            onSelect: onSelectUser,
                            onAppear: { viewModel.loadMoreIfNeeded(displaying: user) }
                        )
                    }
                }

                if viewModel.isLoadingPage {
                    ProgressView()
                        .frame(maxWidth: .infinity)
                        .padding()
                } else if let error = viewModel.error {
                    LikesListErrorFooterView(title: error.title) {
                        viewModel.loadMore()
                    }
                }
            }
        }
    }

    private enum Metrics {
        static let minimumColumnWidth: CGFloat = 300
    }
}

/// Inline footer shown in place of the loading spinner when fetching the next page
/// fails, keeping the already-loaded likes on screen instead of replacing them with
/// a full-screen error.
private struct LikesListErrorFooterView: View {
    let title: String
    let onRetry: () -> Void

    var body: some View {
        VStack(spacing: 8) {
            Text(title)
                .font(.subheadline)
                .foregroundStyle(.secondary)
            Button(SharedStrings.Button.retry, action: onRetry)
                .font(.subheadline.weight(.medium))
        }
        .multilineTextAlignment(.center)
        .frame(maxWidth: .infinity)
        .padding()
    }
}

/// A single tappable liker cell. Using a `Button` gives VoiceOver and Switch Control
/// one labeled control (with the button trait) per row, matching the selectable table
/// row it replaces. The row's global frame is tracked so the host can anchor the profile
/// popover to it on iPad.
private struct LikeUserGridCell: View {
    let user: LikeUser
    let showsDivider: Bool
    let onSelect: (LikeUser, CGRect) -> Void
    let onAppear: () -> Void

    @State private var frame: CGRect = .zero

    var body: some View {
        Button {
            onSelect(user, frame)
        } label: {
            LikeUserRowView(user: user, showsDivider: showsDivider)
                .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .background(
            GeometryReader { proxy in
                Color.clear
                    .onAppear { frame = proxy.frame(in: .global) }
                    .onChange(of: proxy.frame(in: .global)) { _, newValue in
                        frame = newValue
                    }
            }
        )
        .onAppear(perform: onAppear)
    }
}
