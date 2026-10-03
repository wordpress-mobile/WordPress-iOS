import SwiftUI
import WordPressUI

struct CommentReviewView: View {
    @ObservedObject var viewModel: CommentReviewViewModel
    let titleResolver: PostTitleResolver
    let makeContentRenderer: () -> any CommentContentRendering
    @Environment(\.dismiss) private var dismiss

    @AccessibilityFocusState private var isHeadingFocused: Bool

    var body: some View {
        NavigationStack {
            Group {
                if viewModel.isComplete {
                    CommentReviewCompletionView(
                        moderatedCount: viewModel.moderatedCount,
                        skippedCount: viewModel.skippedCount
                    )
                } else if let detail = viewModel.detail {
                    CommentReviewEntryView(
                        detail: detail,
                        session: viewModel,
                        titleResolver: titleResolver,
                        makeContentRenderer: makeContentRenderer
                    )
                    .id(detail.commentID)
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button.make(role: .close, action: close)
                }
                ToolbarItem(placement: .principal) {
                    VStack {
                        Text(Strings.Review.title).font(.headline)
                        if !viewModel.isComplete {
                            Text(
                                String.localizedStringWithFormat(
                                    Strings.Review.position,
                                    viewModel.position + 1,
                                    viewModel.batch.count
                                )
                            )
                            .font(.caption)
                        }
                    }
                    .accessibilityElement(children: .combine)
                    .accessibilityAddTraits(.isHeader)
                    .accessibilityFocused($isHeadingFocused)
                }
                ToolbarItem(placement: .topBarTrailing) {
                    if let id = viewModel.detail?.commentID {
                        Button(Strings.Review.skip) { viewModel.skip(id: id) }
                            .disabled(!viewModel.canSkip)
                    }
                }
            }
            .onChange(of: viewModel.position) { _, _ in isHeadingFocused = true }
        }
        .interactiveDismissDisabled(!viewModel.isComplete)
        .onDisappear { viewModel.close() }
    }

    private func close() {
        viewModel.close()
        dismiss()
    }
}

/// Recreated by comment ID, including the renderer, scroll view, and dialogs.
/// Observes the entry's detail as well as the session because the toolbar's
/// enablement reads the detail's load and mutation state through the session.
private struct CommentReviewEntryView: View {
    @ObservedObject var detail: CommentDetailViewModel
    @ObservedObject var session: CommentReviewViewModel
    let titleResolver: PostTitleResolver
    @StateObject private var content: ReviewContentRenderer

    init(
        detail: CommentDetailViewModel,
        session: CommentReviewViewModel,
        titleResolver: PostTitleResolver,
        makeContentRenderer: @escaping () -> any CommentContentRendering
    ) {
        self.detail = detail
        self.session = session
        self.titleResolver = titleResolver
        _content = StateObject(wrappedValue: ReviewContentRenderer(renderer: makeContentRenderer()))
    }

    var body: some View {
        let id = detail.commentID
        CommentDetailBody(
            viewModel: detail,
            titleResolver: titleResolver,
            renderer: content.renderer,
            retry: { Task { await session.loadCurrent(id: id, retry: true) } }
        )
        .safeAreaInset(edge: .bottom, spacing: 0) {
            CommentModerationToolbar(
                model: .pending,
                isEnabled: session.canModerate,
                pendingAction: session.pendingAction,
                trashConfirmation: detail.trashConfirmation
            ) { action in
                session.perform(action, id: id)
            }
        }
        .task { await session.loadCurrent(id: id) }
    }
}

/// StateObject defers construction until this entry owns its SwiftUI identity.
/// Session updates must not allocate additional WebKit renderers.
private final class ReviewContentRenderer: ObservableObject {
    let renderer: any CommentContentRendering

    init(renderer: any CommentContentRendering) {
        self.renderer = renderer
    }
}

private struct CommentReviewCompletionView: View {
    let moderatedCount: Int
    let skippedCount: Int
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var appeared = false

    var body: some View {
        ViewThatFits(in: .vertical) {
            content(imageFont: .largeTitle)
            content(imageFont: .body)
        }
        .padding(32)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .onAppear {
            withAnimation(reduceMotion || moderatedCount == 0 ? nil : .easeOut(duration: 0.2)) {
                appeared = true
            }
        }
    }

    private func content(imageFont: Font) -> some View {
        VStack(spacing: 20) {
            Image(systemName: moderatedCount > 0 ? "checkmark.circle" : "bubble.left")
                .font(imageFont)
                .imageScale(.large)
                .foregroundStyle(moderatedCount > 0 ? Color.accentColor : .secondary)
                .accessibilityHidden(true)
                .scaleEffect(appeared ? 1 : 0.9)
            Text(Strings.Review.complete)
                .font(.title2.weight(.semibold))
                .accessibilityAddTraits(.isHeader)
            Text(Strings.Review.summary(moderated: moderatedCount, skipped: skippedCount))
        }
        .multilineTextAlignment(.center)
        .fixedSize(horizontal: false, vertical: true)
    }
}

#Preview("Moderated") {
    CommentReviewCompletionView(moderatedCount: 5, skippedCount: 0)
}

#Preview("Skipped") {
    CommentReviewCompletionView(moderatedCount: 0, skippedCount: 5)
}

#Preview("Mixed results") {
    CommentReviewCompletionView(moderatedCount: 3, skippedCount: 2)
}

#Preview("Already handled") {
    CommentReviewCompletionView(moderatedCount: 0, skippedCount: 0)
}
