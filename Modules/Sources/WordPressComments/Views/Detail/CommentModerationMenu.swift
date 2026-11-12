import SwiftUI

/// Keeps moderation reachable when large controls cannot fit above the app tab bar.
struct CommentModerationMenu<Content: View>: View {
    private let model: CommentModerationToolbarModel
    private let isEnabled: Bool
    private let isPerformingAction: Bool
    private let trashConfirmation: CommentDetailViewModel.TrashConfirmation
    private let perform: (CommentModerationAction) -> Void
    private let content: Content

    @State private var isTrashConfirmationPresented = false
    @State private var isDeleteConfirmationPresented = false

    init(
        model: CommentModerationToolbarModel,
        isEnabled: Bool,
        isPerformingAction: Bool,
        trashConfirmation: CommentDetailViewModel.TrashConfirmation,
        perform: @escaping (CommentModerationAction) -> Void,
        @ViewBuilder content: () -> Content
    ) {
        self.model = model
        self.isEnabled = isEnabled
        self.isPerformingAction = isPerformingAction
        self.trashConfirmation = trashConfirmation
        self.perform = perform
        self.content = content()
    }

    var body: some View {
        Menu {
            content
            if model != .hidden {
                Section {
                    actions
                }
                .disabled(!isEnabled)
            }
        } label: {
            if isPerformingAction {
                ProgressView()
            } else {
                Image(systemName: "ellipsis")
            }
        }
        .accessibilityLabel(Strings.detailMoreActions)
        .confirmationDialog(
            trashConfirmationTitle,
            isPresented: $isTrashConfirmationPresented,
            titleVisibility: .visible
        ) {
            Button(Strings.trashConfirmButton, role: .destructive) { perform(.trash) }
        }
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

    @ViewBuilder
    private var actions: some View {
        switch model {
        case .pending:
            action(.approve)
            action(.spam)
            action(.trash)
        case .approved:
            action(.spam)
            action(.trash)
        case .inBin:
            action(.restore)
            action(.delete)
        case .hidden:
            EmptyView()
        }
    }

    private func action(_ action: CommentModerationAction) -> some View {
        Button(action.title, systemImage: action.systemImage, role: action.role) {
            switch action {
            case .trash:
                switch trashConfirmation {
                case .none: perform(.trash)
                case .generic, .withReplies: isTrashConfirmationPresented = true
                }
            case .delete:
                isDeleteConfirmationPresented = true
            default:
                perform(action)
            }
        }
    }

    private var trashConfirmationTitle: String {
        if case .withReplies = trashConfirmation {
            return Strings.trashHasReplies
        }
        return Strings.trashConfirmGenericTitle
    }
}
