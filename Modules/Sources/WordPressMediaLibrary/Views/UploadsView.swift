import SwiftUI

struct UploadsView: View {
    @ObservedObject var viewModel: MediaLibraryViewModel
    @State private var isConfirmingCancelAll = false
    @State private var emptyState = UploadsEmptyStateTracker()

    var body: some View {
        Group {
            if viewModel.uploadsScreenItems.isEmpty {
                emptyView
            } else {
                List(viewModel.uploadsScreenItems) { item in
                    UploadRow(
                        item: item,
                        onCancel: {
                            emptyState.userWillRemove([item.id])
                            Task { await viewModel.cancelUpload(item.id) }
                        },
                        onRetry: { Task { await viewModel.retryUpload(item.id) } },
                        onRemove: {
                            emptyState.userWillRemove([item.id])
                            Task { await viewModel.removeUpload(item.id) }
                        }
                    )
                }
                .listStyle(.plain)
            }
        }
        .onChange(of: viewModel.uploadsScreenItems.map(\.id)) { oldIDs, newIDs in
            emptyState.listChanged(from: oldIDs, to: newIDs)
        }
        .navigationTitle(Strings.uploadsScreenTitle)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                bulkMenu
            }
        }
        .alert(Strings.uploadBulkCancelAll, isPresented: $isConfirmingCancelAll) {
            Button(Strings.uploadBulkCancelAllConfirm, role: .destructive) {
                emptyState.userWillRemove(uploadingIDs)
                Task { await viewModel.cancelAllUploads() }
            }
            Button(Strings.keepUploading, role: .cancel) {}
        } message: {
            Text(Strings.uploadBulkCancelAllMessage)
        }
    }

    @ViewBuilder private var bulkMenu: some View {
        if hasAnyBulkAction {
            Menu {
                if hasRetryableFailed {
                    Button {
                        Task { await viewModel.retryAllUploads() }
                    } label: {
                        Label(Strings.uploadBulkRetryAll, systemImage: "arrow.clockwise")
                    }
                }
                if hasFailed {
                    Button(role: .destructive) {
                        emptyState.userWillRemove(failedIDs)
                        Task { await viewModel.removeAllFailedUploads() }
                    } label: {
                        Label(Strings.uploadBulkRemoveAll, systemImage: "trash")
                    }
                }
                if hasUploading {
                    Button(role: .destructive) {
                        isConfirmingCancelAll = true
                    } label: {
                        Label(Strings.uploadBulkCancelAll, systemImage: "xmark.circle")
                    }
                }
            } label: {
                Image(systemName: "ellipsis")
            }
        }
    }

    @ViewBuilder private var emptyView: some View {
        switch emptyState.state {
        case .noUploads:
            ContentUnavailableView {
                Label(Strings.uploadsScreenEmpty, systemImage: "tray")
            }
        case .allUploaded:
            ContentUnavailableView {
                Label(Strings.uploadsScreenAllUploaded, systemImage: "checkmark.circle")
            }
        }
    }

    private var uploadingIDs: [UUID] {
        viewModel.uploadsScreenItems.compactMap { row in
            if case .uploading = row.mode { return row.id }
            return nil
        }
    }
    private var failedIDs: [UUID] {
        viewModel.uploadsScreenItems.compactMap { row in
            if case .failed = row.mode { return row.id }
            return nil
        }
    }
    private var hasUploading: Bool { !uploadingIDs.isEmpty }
    private var hasFailed: Bool { !failedIDs.isEmpty }
    private var hasRetryableFailed: Bool {
        viewModel.uploadsScreenItems.contains { row in
            if case .failed(_, let isRetryable) = row.mode { return isRetryable }
            return false
        }
    }
    private var hasAnyBulkAction: Bool { hasUploading || hasFailed }
}

/// Picks the Uploads screen's empty state. The uploader drops an entry as soon
/// as its upload finishes, so without this the open screen would switch to
/// "No Uploads" right after a success, which reads as if the upload was lost.
struct UploadsEmptyStateTracker {
    enum State: Equatable {
        case noUploads
        case allUploaded
    }

    private(set) var state = State.noUploads
    private var userRemovedIDs: Set<UUID> = []

    /// Records rows the user is cancelling or removing, so their disappearance
    /// isn't mistaken for a finished upload.
    mutating func userWillRemove(_ ids: [UUID]) {
        userRemovedIDs.formUnion(ids)
    }

    /// The list emptied because an upload finished if any row in the last
    /// change left without a user action.
    mutating func listChanged(from oldIDs: [UUID], to newIDs: [UUID]) {
        if newIDs.isEmpty, !oldIDs.isEmpty {
            let removedIDs = Set(oldIDs).subtracting(newIDs)
            state = removedIDs.isSubset(of: userRemovedIDs) ? .noUploads : .allUploaded
        }
        userRemovedIDs.formIntersection(newIDs)
    }
}
