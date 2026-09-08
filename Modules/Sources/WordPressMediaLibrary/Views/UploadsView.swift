import SwiftUI

struct UploadsView: View {
    @ObservedObject var viewModel: MediaLibraryViewModel
    @State private var isConfirmingCancelAll = false

    var body: some View {
        Group {
            if viewModel.uploadsScreenItems.isEmpty {
                ContentUnavailableView {
                    Label(Strings.uploadsScreenEmpty, systemImage: "tray")
                }
            } else {
                List(viewModel.uploadsScreenItems) { item in
                    UploadRow(
                        item: item,
                        onCancel: { Task { await viewModel.cancelUpload(item.id) } },
                        onRetry: { Task { await viewModel.retryUpload(item.id) } },
                        onRemove: { Task { await viewModel.removeUpload(item.id) } }
                    )
                }
                .listStyle(.plain)
            }
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

    private var hasUploading: Bool {
        viewModel.uploadsScreenItems.contains { row in
            if case .uploading = row.mode { return true }
            return false
        }
    }
    private var hasFailed: Bool {
        viewModel.uploadsScreenItems.contains { row in
            if case .failed = row.mode { return true }
            return false
        }
    }
    private var hasRetryableFailed: Bool {
        viewModel.uploadsScreenItems.contains { row in
            if case .failed(_, let isRetryable) = row.mode { return isRetryable }
            return false
        }
    }
    private var hasAnyBulkAction: Bool { hasUploading || hasFailed }
}
