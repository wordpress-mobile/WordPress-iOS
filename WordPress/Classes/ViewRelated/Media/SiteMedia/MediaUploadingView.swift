import Foundation
import SwiftUI
import WordPressData
import Combine

struct MediaUploadingView: View {

    private let mediaUploadService: MediaUploadService
    private let assets: [ExportableAsset]

    @State private var uploadItems: [UploadItemState] = []
    @State private var isUploading = false
    @State private var cancellation: AnyCancellable? = nil

    @Environment(\.dismiss) private var dismiss

    init(mediaUploadService: MediaUploadService, assets: [ExportableAsset]) {
        self.mediaUploadService = mediaUploadService
        self.assets = assets
    }

    var body: some View {
        NavigationView {
            List {
                Section {
                    ForEach(uploadItems.indices, id: \ .self) { index in
                        AssetUploadRow(
                            asset: uploadItems[index].asset,
                            uploadState: uploadItems[index].state,
                            progress: uploadItems[index].progress,
                            thumbnailURL: uploadItems[index].thumbnailURL,
                            onRetry: {
                                Task {
                                    await uploadAsset(at: index)
                                }
                            }
                        )
                    }
                }
                .listSectionSeparator(.hidden)
                .listRowSeparator(.hidden)
            }
            .listStyle(.plain)
            .navigationTitle(Strings.uploadingMediaTitle)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    if isUploading {
                        Button(Strings.stopUploads, action: cancelAllUploads)
                    } else if hasUnfinishedUploads {
                        Button(Strings.restartUploads) {
                            Task {
                                await startUploads()
                            }
                        }
                    }
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    if !isUploading {
                        Button(SharedStrings.Button.done) {
                            dismiss()
                        }
                    }
                }
            }
        }
        .interactiveDismissDisabled(isUploading)
        .task {
            await startUploads()
        }
    }

    private func startUploads() async {
        if self.uploadItems.isEmpty {
            self.uploadItems = assets.map { asset in
                UploadItemState(asset: asset, state: .notStarted, thumbnailURL: nil)
            }
        }

        isUploading = true
        defer { isUploading = false }

        await withTaskGroup(of: Void.self) { group in
            self.cancellation = .init(group.cancelAll)

            for (index, item) in uploadItems.enumerated() where item.state.shouldUpload {
                group.addTask {
                    await uploadAsset(at: index)
                }
            }
        }

        self.cancellation = nil
    }

    private func cancelAllUploads() {
        guard cancellation != nil else { return }

        cancellation?.cancel()
        cancellation = nil
        isUploading = false

        for index in uploadItems.indices {
            switch uploadItems[index].state {
            case .notStarted, .uploading:
                uploadItems[index].state = .cancelled
            case .success, .failed, .cancelled:
                // Do nothing.
                break
            }

            uploadItems[index].progress?.cancel()
        }
    }

    private var hasUnfinishedUploads: Bool {
        uploadItems.contains { $0.state.shouldUpload }
    }

    private func uploadAsset(at index: Int) async {
        let asset = uploadItems[index].asset
        uploadItems[index].state = .uploading

        do {
            let mediaID = try await mediaUploadService.uploadToMediaLibrary(asset: asset, observer: self)
            uploadItems[index].state = .success(mediaID: mediaID)
        } catch is CancellationError {
            uploadItems[index].state = .cancelled
        } catch {
            uploadItems[index].state = .failed(error: error)
        }
    }
}

extension MediaUploadingView: MediaUploadServiceEventObserver {
    func handle(event: MediaUploadService.Event, asset: any ExportableAsset, service: MediaUploadService) {
        guard let index = uploadItems.firstIndex(where: { $0.asset === asset }) else {
            return
        }

        switch event {
        case let .overallProgress(progress):
            uploadItems[index].progress = progress
        case let .thumbnail(url):
            uploadItems[index].thumbnailURL = url
        }
    }
}

private enum UploadState {
    case notStarted
    case uploading
    case success(mediaID: TaggedManagedObjectID<Media>)
    case failed(error: Error)
    case cancelled

    var shouldUpload: Bool {
        switch self {
        case .notStarted, .failed, .cancelled:
            return true
        default:
            return false
        }
    }
}

private struct AssetUploadRow: View {
    let asset: ExportableAsset
    let uploadState: UploadState
    let progress: Progress?
    let thumbnailURL: URL?
    let onRetry: () -> Void

    var body: some View {
        HStack(alignment: .center, spacing: 16) {
            AsyncImage(url: thumbnailURL) { image in
                image.resizable().scaledToFill()
            } placeholder: {
                Image(systemName: "photo")
                    .resizable()
                    .scaledToFit()
                    .foregroundColor(.secondary)
            }
            .frame(width: 44, height: 44)
            .cornerRadius(8)
            .clipped()

            Text(assetName)
                .font(.body)
                .foregroundColor(.primary)
                .lineLimit(2)

            Spacer()

            statusView
                .frame(width: 32, height: 32)
        }
        .padding(.vertical, 8)
    }

    // MARK: - Status View (Right Side)
    @ViewBuilder
    var statusView: some View {
        switch uploadState {
        case .uploading:
            if let progress {
                CircularProgressBarView(progress: progress)
            }
        case .success:
            Image(systemName: "checkmark.circle.fill")
                .font(.title2)
        case .failed:
            Button(action: onRetry) {
                Image(systemName: "exclamationmark.circle.fill")
                    .font(.title2)
            }
            .buttonStyle(.plain)
        default:
            EmptyView()
        }
    }

    var assetName: String {
        switch asset {
        case let url as URL:
            return url.lastPathComponent
        case let provider as NSItemProvider:
            return provider.suggestedName ?? "-"
        default:
            return "-"
        }
    }
}

private struct CircularProgressBarView: View {
    let progress: Progress

    @State private var fractionCompleted: Double = 0.0

    var body: some View {
        ZStack {
            Circle()
                .stroke(
                    Color.accentColor.opacity(0.5),
                    lineWidth: 4
                )
            Circle()
                .trim(from: 0, to: fractionCompleted)
                .stroke(
                    Color.accentColor,
                    style: StrokeStyle(
                        lineWidth: 4,
                        lineCap: .round
                    )
                )
                .rotationEffect(.degrees(-90))
                .animation(.easeOut, value: fractionCompleted)

        }
        .frame(width: 20, height: 20)
        .onAppear {
            fractionCompleted = progress.fractionCompleted
        }
        .onChange(of: progress) {
            fractionCompleted = $0.fractionCompleted
        }
        .onReceive(progress.publisher(for: \.fractionCompleted)) {
            self.fractionCompleted = $0
        }
    }
}

// MARK: - Array Extension

extension Array {
    subscript(safe index: Index) -> Element? {
        return indices.contains(index) ? self[index] : nil
    }
}

private enum Strings {
    static let uploadingMediaTitle = NSLocalizedString("media.uploading.title", value: "Uploading Media", comment: "Title for the media uploading modal")
    static let stopUploads = NSLocalizedString("media.uploading.stop", value: "Stop", comment: "Accessibility label for stop uploads button")
    static let restartUploads = NSLocalizedString("media.uploading.restart", value: "Restart", comment: "Accessibility label for restart uploads button")
    static let uploadComplete = NSLocalizedString("media.uploading.complete", value: "Upload complete", comment: "Subtitle shown when upload is complete")
    static let uploadFailed = NSLocalizedString("media.uploading.failed", value: "Upload failed", comment: "Subtitle shown when upload failed")
}

private struct UploadItemState {
    var asset: ExportableAsset
    var state: UploadState
    var progress: Progress?
    var thumbnailURL: URL?
}
