import SwiftUI

struct UploadsView: View {
    @ObservedObject var viewModel: MediaLibraryViewModel
    @State private var isConfirmingCancelAll = false

    var body: some View {
        Group {
            if viewModel.uploadsScreenItems.isEmpty {
                ContentUnavailableView {
                    Label(Strings.uploadsScreenAllDone, systemImage: "checkmark.circle")
                }
            } else {
                List(viewModel.uploadsScreenItems) { item in
                    UploadRow(
                        item: item,
                        onCancel: { Task { await viewModel.cancelUpload(item.id) } },
                        onRetry: { Task { await viewModel.retryUpload(item.id) } },
                        onDismiss: { Task { await viewModel.dismissUpload(item.id) } }
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
            Button(Strings.cancel, role: .cancel) {}
        } message: {
            Text(Strings.uploadBulkCancelAllMessage)
        }
    }

    @ViewBuilder private var bulkMenu: some View {
        if hasAnyBulkAction {
            Menu {
                if hasRetryableFailed {
                    Button(Strings.uploadBulkRetryAll) {
                        Task { await viewModel.retryAllUploads() }
                    }
                }
                if hasFailed {
                    Button(Strings.uploadBulkDismissAll, role: .destructive) {
                        Task { await viewModel.dismissAllUploads() }
                    }
                }
                if hasUploading {
                    Button(Strings.uploadBulkCancelAll, role: .destructive) {
                        isConfirmingCancelAll = true
                    }
                }
            } label: {
                Image(systemName: "ellipsis.circle")
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
