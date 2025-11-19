import SwiftUI
import PhotosUI

struct ScreenshotPicker: View {

    enum ViewState: Sendable {
        case ready
        case loading
        case error(Error)

        var isLoadingMoreImages: Bool {
            guard case .loading = self else { return false }
            return true
        }

        var error: Error? {
            guard case .error(let error) = self else { return nil }
            return error
        }
    }

    private let maxScreenshots = 10

    @State
    private var selectedPhotos: [PhotosPickerItem] = []

    @State
    private var attachedImages: [UIImage] = []

    @State
    private var state: ViewState = .ready

    @Binding
    var attachedImageUrls: [URL]

    @State
    private var currentUploadSize: CGFloat = 0

    let maximumUploadSize: CGFloat?

    @Binding
    var uploadLimitExceeded: Bool

    var body: some View {
        Section {
            Text(Localization.screenshotsDescription)
                .font(.body)
                .foregroundColor(.secondary)

                if let error = self.state.error {
                    ErrorView(
                        title: "Unable to load screenshot",
                        message: error.localizedDescription
                    )
                }

                if !attachedImages.isEmpty {
                    imageGallery
                    maxSizeIndicator
                }

                // Add screenshots button
                PhotosPicker(
                    selection: $selectedPhotos,
                    maxSelectionCount: maxScreenshots,
                    matching: .any(of: [
                        .screenshots,
                        .screenRecordings
                    ])
                ) { [imageCount = attachedImages.count, isLoading = self.state.isLoadingMoreImages, uploadLimitExceeded = self.uploadLimitExceeded] in
                    HStack {
                        if isLoading {
                            ProgressView()
                                .tint(Color.accentColor)
                        } else {
                            Image(systemName: "camera.fill")
                        }

                        Text(imageCount == 0 ? Localization.addScreenshots : Localization.addMoreScreenshots)
                    }
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.accentColor.opacity(0.1))
                    .foregroundStyle(uploadLimitExceeded ? Color.gray : Color.accentColor)
                    .cornerRadius(8)
                }
                .onChange(of: selectedPhotos) { _, newItems in
                    Task {
                        self.state = .loading
                        await loadSelectedPhotos(newItems)
                        self.state = .ready
                    }
                }
                .disabled(uploadLimitExceeded)
        } header: {
            HStack {
                Text(Localization.screenshots)
                Text(Localization.optional)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .listRowSeparator(.hidden)
        .selectionDisabled()
    }

    @ViewBuilder
    var imageGallery: some View {
        // Screenshots display
        ScrollView(.horizontal, showsIndicators: false) {
            LazyHStack(spacing: 12) {
                ForEach(Array(attachedImages.enumerated()), id: \.offset) { index, image in
                    ZStack(alignment: .topTrailing) {
                        Image(uiImage: image)
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                            .frame(width: 80, height: 80)
                            .clipped()
                            .cornerRadius(8)

                        // Remove button
                        Button {
                            // attachedImages will be updated by changing `selectedPhotos`, but not immediately. This line is here to make the UI feel snappy
                            attachedImages.remove(at: index)
                            selectedPhotos.remove(at: index)
                        } label: {
                            Image(systemName: "xmark.circle.fill")
                                .foregroundColor(.red)
                                .background(Color.white, in: Circle())
                        }
                        .padding(4)
                    }
                }
            }
            .padding(.horizontal, 2)
        }
    }

    @ViewBuilder
    var maxSizeIndicator: some View {
        if let maximumUploadSize {
            VStack(alignment: .leading) {
                ProgressView(value: currentUploadSize, total: maximumUploadSize)
                    .tint(uploadLimitExceeded ? Color.red : Color.accentColor)

                Text(String.localizedStringWithFormat(Localization.attachmentLimit, format(bytes: currentUploadSize), format(bytes: maximumUploadSize)))
                    .font(.caption2)
                    .foregroundStyle(Color.secondary)
            }
        }
    }

    private func format(bytes: CGFloat) -> String {
        ByteCountFormatter().string(fromByteCount: Int64(bytes))
    }

    /// Loads selected photos from PhotosPicker
    @MainActor
    func loadSelectedPhotos(_ items: [PhotosPickerItem]) async {
        var newImages: [UIImage] = []
        var newUrls: [URL] = []
        var totalSize: CGFloat = 0

        do {
            for item in items {
                if let data = try await item.loadTransferable(type: Data.self) {
                    if let image = UIImage(data: data) {
                        newImages.append(image)
                    }

                    totalSize += CGFloat(data.count)
                }

                if let file = try await item.loadTransferable(type: ScreenshotFile.self) {
                    newUrls.append(file.url)
                }
            }

            self.attachedImages = newImages
            self.attachedImageUrls = newUrls

            withAnimation {
                self.currentUploadSize = totalSize
                self.uploadLimitExceeded = totalSize > maximumUploadSize ?? .infinity
            }
        } catch {
            withAnimation {
                self.state = .error(error)
            }
        }
    }
}

/// File representation
struct ScreenshotFile: Transferable {
    let url: URL

    var filename: String {
        url.lastPathComponent
    }

    private static let cacheDirectoryName: String = "screenshot-cache"

    static var transferRepresentation: some TransferRepresentation {
        FileRepresentation(contentType: .image) {
            return SentTransferredFile($0.url)
        } importing: { received in
            let directory = URL.cachesDirectory
                .appendingPathComponent(cacheDirectoryName)
                .appendingPathComponent(UUID().uuidString)

            try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)

            let destination = directory.appendingPathComponent(received.file.lastPathComponent)

            try FileManager.default.copyItem(at: received.file, to: destination)

            return Self(url: destination)
        }
    }
}

#Preview {
    struct Preview: View {
        @State
        var selectedPhotoUrls: [URL] = []

        var body: some View {
            Form {
                ScreenshotPicker(
                    attachedImageUrls: $selectedPhotoUrls,
                    maximumUploadSize: 10_000_000,
                    uploadLimitExceeded: .constant(false)
                )
            }
            .environmentObject(SupportDataProvider.testing)
        }
    }

    return Preview()
}
