import SwiftUI
import PhotosUI

struct ScreenshotPicker: View {

    private let maxScreenshots = 5

    @State
    private var selectedPhotos: [PhotosPickerItem] = []

    @State
    private var attachedImages: [UIImage] = []

    @State
    private var error: Error?

    @Binding
    var attachedImageUrls: [URL]

    var body: some View {
        Section {
            VStack(alignment: .leading, spacing: 12) {
                Text(Localization.screenshotsDescription)
                    .font(.caption)
                    .foregroundColor(.secondary)

                // Screenshots display
                if !attachedImages.isEmpty {
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

                if let error {
                    ErrorView(
                        title: "Unable to load screenshot",
                        message: error.localizedDescription
                    ).frame(maxWidth: .infinity)
                }

                // Add screenshots button
                PhotosPicker(
                    selection: $selectedPhotos,
                    maxSelectionCount: maxScreenshots,
                    matching: .images
                ) { [imageCount = attachedImages.count] in
                    HStack {
                        Image(systemName: "camera.fill")
                        Text(imageCount == 0 ? Localization.addScreenshots : Localization.addMoreScreenshots)
                    }
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.accentColor.opacity(0.1))
                    .foregroundColor(Color.accentColor)
                    .cornerRadius(8)
                }
                .onChange(of: selectedPhotos) { _, newItems in
                    Task {
                        await loadSelectedPhotos(newItems)
                    }
                }
            }
        } header: {
            HStack {
                Text(Localization.screenshots)
                Text(Localization.optional)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
    }

    /// Loads selected photos from PhotosPicker
    func loadSelectedPhotos(_ items: [PhotosPickerItem]) async {
        var newImages: [UIImage] = []
        var newUrls: [URL] = []

        do {
            for item in items {
                if let data = try await item.loadTransferable(type: Data.self) {
                    if let image = UIImage(data: data) {
                        newImages.append(image)
                    }
                }

                if let file = try await item.loadTransferable(type: ScreenshotFile.self) {
                    newUrls.append(file.url)
                }
            }

            await MainActor.run {
                attachedImages = newImages
                attachedImageUrls = newUrls
            }
        } catch {
            await MainActor.run {
                withAnimation {
                    self.error = error
                }
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
                ScreenshotPicker(attachedImageUrls: $selectedPhotoUrls)
            }
            .environmentObject(SupportDataProvider.testing)
        }
    }

    return Preview()
}
