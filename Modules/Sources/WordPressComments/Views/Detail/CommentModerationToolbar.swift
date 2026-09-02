import SwiftUI

/// Pure description of the bottom moderation toolbar's shape for a given
/// comment status. Derived once from the live header status and the view
/// model's `showsToolbar`, so the toolbar never has to branch on raw status.
enum CommentModerationToolbarModel: Equatable {
    case pending // Approve (prominent) over Spam | Trash
    case approved // Spam | Trash
    case inBin // Restore over Delete Permanently
    case hidden // custom status, no capability, or forced off

    static func make(
        status: CommentListItem.Status?,
        showsToolbar: Bool
    ) -> CommentModerationToolbarModel {
        guard showsToolbar, let status else { return .hidden }
        return switch status {
        case .pending: .pending
        case .approved: .approved
        case .spam, .trash: .inBin
        case .other: .hidden
        }
    }

    /// The secondary moderation action that lives in the nav bar overflow
    /// menu rather than the toolbar, so the toolbar shows only the common moves.
    var menuAction: CommentModerationAction? {
        switch self {
        case .approved: .unapprove
        case .pending, .inBin, .hidden: nil
        }
    }
}

/// How each action presents as a button: shared by the toolbar and the nav
/// bar overflow menu so a title, symbol, and role are defined once.
extension CommentModerationAction {
    var title: String {
        switch self {
        case .approve: Strings.approve
        case .unapprove: Strings.moveToPending
        case .spam: Strings.spam
        case .trash: Strings.trash
        case .restore: Strings.restore
        case .delete: Strings.deletePermanently
        }
    }

    var systemImage: String {
        switch self {
        case .approve: "checkmark"
        case .unapprove: "clock"
        case .spam: "exclamationmark.bubble"
        case .trash: "trash"
        case .restore: "arrow.uturn.backward"
        case .delete: "trash"
        }
    }

    var role: ButtonRole? {
        switch self {
        case .spam, .trash, .delete: .destructive
        case .approve, .unapprove, .restore: nil
        }
    }
}

/// The pinned bottom moderation bar. Hosted via `.safeAreaInset(edge: .bottom)`
/// so it renders inside the UIKit `UIHostingController`; Trash gates behind a
/// confirmation dialog when the comment has replies, Delete Permanently always.
/// Each dialog is attached to its own button so it anchors there when
/// presented as a popover.
struct CommentModerationToolbar: View {
    let model: CommentModerationToolbarModel
    let isEnabled: Bool
    /// The action whose request is in flight; its button shows a spinner in
    /// place of its label while the pessimistic request round-trips.
    let pendingAction: CommentModerationAction?
    let trashConfirmation: CommentDetailViewModel.TrashConfirmation
    let perform: (CommentModerationAction) -> Void

    @State private var isTrashConfirmationPresented = false
    @State private var isDeleteConfirmationPresented = false

    var body: some View {
        buttons
            .controlSize(.large)
            .disabled(!isEnabled)
            .padding(.horizontal)
            .padding(.vertical, 10)
            .frame(maxWidth: .infinity)
    }

    @ViewBuilder
    private var buttons: some View {
        switch model {
        case .pending:
            VStack(spacing: 10) {
                approveButton
                spamTrashRow
            }
        case .approved:
            spamTrashRow
        case .inBin:
            VStack(spacing: 10) {
                restoreButton
                deleteButton
            }
        case .hidden:
            EmptyView()
        }
    }

    private var approveButton: some View {
        button(for: .approve) { perform(.approve) }
            .buttonStyle(.borderedProminent)
    }

    private var spamTrashRow: some View {
        HStack(spacing: 10) {
            button(for: .spam) { perform(.spam) }
            button(for: .trash) { requestTrash() }
                .confirmationDialog(
                    trashConfirmationTitle,
                    isPresented: $isTrashConfirmationPresented,
                    titleVisibility: .visible
                ) {
                    Button(Strings.trashConfirmButton, role: .destructive) { perform(.trash) }
                }
        }
        .buttonStyle(.bordered)
    }

    private var restoreButton: some View {
        button(for: .restore) { perform(.restore) }
            .buttonStyle(.bordered)
    }

    private var deleteButton: some View {
        button(for: .delete) { isDeleteConfirmationPresented = true }
            .buttonStyle(.bordered)
            .confirmationDialog(
                Strings.deleteConfirmTitle,
                isPresented: $isDeleteConfirmationPresented,
                titleVisibility: .visible
            ) {
                Button(Strings.deletePermanently, role: .destructive) { perform(.delete) }
            } message: {
                Text(Strings.deleteConfirmMessage)
            }
    }

    /// A full-width button for `action`, its label overlaid by a spinner while
    /// its own action is the one in flight. The label stays in the layout
    /// (hidden) so the button keeps its height, and the spinner keeps the
    /// action's name so VoiceOver still says which action is running.
    private func button(for action: CommentModerationAction, tap: @escaping () -> Void) -> some View {
        let isPending = pendingAction == action
        return Button(role: action.role, action: tap) {
            Label(action.title, systemImage: action.systemImage)
                .opacity(isPending ? 0 : 1)
                .overlay {
                    if isPending {
                        ProgressView()
                            .controlSize(.regular)
                            .accessibilityLabel(action.title)
                    }
                }
                .frame(maxWidth: .infinity)
        }
    }

    /// Trash confirms only when the comment has replies (known or unknown
    /// count); a leaf comment trashes without a prompt.
    private func requestTrash() {
        switch trashConfirmation {
        case .none:
            perform(.trash)
        case .generic, .withReplies:
            isTrashConfirmationPresented = true
        }
    }

    private var trashConfirmationTitle: String {
        if case .withReplies = trashConfirmation {
            return Strings.trashHasReplies
        }
        return Strings.trashConfirmGenericTitle
    }
}
