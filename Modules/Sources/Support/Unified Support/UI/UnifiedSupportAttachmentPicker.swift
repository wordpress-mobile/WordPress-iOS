import PhotosUI
import QuickLookThumbnailing
import SwiftUI

/// The section of the reply form used to attach images and videos.
///
/// Files are taken up to the upload limit, in the order they were picked. The ones that don't fit are listed, so the
/// user can make room for them by removing another file.
struct UnifiedSupportAttachmentPicker: View {

    @Binding var files: [UnifiedSupportPickedFile]

    let maximumUploadSize: UInt64

    @State private var selection: [PhotosPickerItem] = []

    /// The picker item each file was loaded from, used to keep the picker and the list in sync.
    @State private var items: [UUID: PhotosPickerItem] = [:]

    @State private var isLoading = false
    @State private var loadingErrorMessage: String?

    private var validation: UnifiedSupportAttachmentValidator.Result {
        UnifiedSupportAttachmentValidator(maximumUploadSize: maximumUploadSize).validate(files)
    }

    var body: some View {
        Section {
            Text(UnifiedSupportLocalization.attachmentsDescription)
                .font(.body)
                .foregroundStyle(.secondary)

            if let loadingErrorMessage {
                ErrorView(title: UnifiedSupportLocalization.attachmentsFailedTitle, message: loadingErrorMessage)
            }

            if !files.isEmpty {
                gallery
                uploadSizeIndicator
            }

            if !validation.skipped.isEmpty {
                skippedFiles
            }

            picker
        } header: {
            HStack {
                Text(UnifiedSupportLocalization.attachments)
                Text(UnifiedSupportLocalization.optional)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .listRowSeparator(.hidden)
    }

    private var picker: some View {
        PhotosPicker(selection: $selection, matching: .any(of: [.images, .videos])) {
            HStack {
                if isLoading {
                    ProgressView()
                        .tint(Color.accentColor)
                } else {
                    Image(systemName: "paperclip")
                }

                Text(
                    files.isEmpty
                        ? UnifiedSupportLocalization.addAttachments
                        : UnifiedSupportLocalization.addMoreAttachments
                )
            }
            .frame(maxWidth: .infinity)
            .padding()
            .background(Color.accentColor.opacity(0.1))
            .foregroundStyle(Color.accentColor)
            .clipShape(RoundedRectangle(cornerRadius: 8))
        }
        .onChange(of: selection) { _, newSelection in
            Task {
                await load(newSelection)
            }
        }
    }

    private var gallery: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            LazyHStack(spacing: 12) {
                ForEach(files) { file in
                    ZStack(alignment: .topTrailing) {
                        UnifiedSupportAttachmentThumbnail(file: file)
                            .opacity(validation.skipped.contains(file) ? 0.4 : 1)

                        Button {
                            remove(file)
                        } label: {
                            Image(systemName: "xmark.circle.fill")
                                .foregroundStyle(Color(.systemRed))
                                .background(Color.white, in: Circle())
                        }
                        .buttonStyle(.plain)
                        .padding(4)
                        .accessibilityLabel(
                            String.localizedStringWithFormat(
                                UnifiedSupportLocalization.removeAttachment,
                                file.filename
                            )
                        )
                    }
                }
            }
            .padding(.horizontal, 2)
        }
    }

    private var uploadSizeIndicator: some View {
        VStack(alignment: .leading) {
            ProgressView(
                value: Double(min(validation.acceptedSize, maximumUploadSize)),
                total: Double(maximumUploadSize)
            )
            .tint(validation.skipped.isEmpty ? Color.accentColor : Color(.systemRed))

            Text(
                String.localizedStringWithFormat(
                    UnifiedSupportLocalization.attachmentsSize,
                    format(bytes: validation.acceptedSize),
                    format(bytes: maximumUploadSize)
                )
            )
            .font(.caption2)
            .foregroundStyle(.secondary)
        }
    }

    private var skippedFiles: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(UnifiedSupportLocalization.attachmentsSkipped)
                .font(.caption)
                .foregroundStyle(Color(.systemRed))

            ForEach(validation.skipped) { file in
                Text("\(file.filename) · \(format(bytes: file.fileSize))")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }
        }
    }

    private func remove(_ file: UnifiedSupportPickedFile) {
        files.removeAll { $0.id == file.id }

        if let item = items.removeValue(forKey: file.id) {
            selection.removeAll { $0 == item }
        }
        UnifiedSupportAttachmentStorage.delete(file)
    }

    /// Loads the files the user just picked, and drops the ones they deselected in the picker.
    private func load(_ newSelection: [PhotosPickerItem]) async {
        let selected = Set(newSelection)
        for file in files where items[file.id].map({ !selected.contains($0) }) ?? false {
            files.removeAll { $0.id == file.id }
            items.removeValue(forKey: file.id)
            UnifiedSupportAttachmentStorage.delete(file)
        }

        let loaded = Set(items.values)
        let newItems = newSelection.filter { !loaded.contains($0) }
        guard !newItems.isEmpty else {
            return
        }

        isLoading = true
        loadingErrorMessage = nil

        for item in newItems {
            do {
                guard let file = try await item.loadTransferable(type: UnifiedSupportPickedFile.self) else {
                    continue
                }
                items[file.id] = item
                files.append(file)
            } catch {
                loadingErrorMessage = error.unifiedSupportMessage
            }
        }

        isLoading = false
    }

    private func format(bytes: UInt64) -> String {
        ByteCountFormatter().string(fromByteCount: Int64(bytes))
    }
}

/// A preview of a picked file, generated by QuickLook so it works for images and videos alike.
private struct UnifiedSupportAttachmentThumbnail: View {

    let file: UnifiedSupportPickedFile

    private static let size = CGSize(width: 80, height: 80)

    @State private var image: UIImage?

    var body: some View {
        Group {
            if let image {
                Image(uiImage: image)
                    .resizable()
                    .aspectRatio(contentMode: .fill)
            } else {
                Color(.systemGray5)
                    .overlay {
                        Image(systemName: "doc")
                            .foregroundStyle(.secondary)
                    }
            }
        }
        .frame(width: Self.size.width, height: Self.size.height)
        .clipShape(RoundedRectangle(cornerRadius: 8))
        .accessibilityLabel(file.filename)
        .task(id: file.id) {
            image = await generateThumbnail()
        }
    }

    private func generateThumbnail() async -> UIImage? {
        let request = QLThumbnailGenerator.Request(
            fileAt: file.url,
            size: Self.size,
            scale: UITraitCollection.current.displayScale,
            representationTypes: .thumbnail
        )
        let thumbnail = try? await QLThumbnailGenerator.shared.generateBestRepresentation(for: request)
        return thumbnail?.uiImage
    }
}

#Preview {
    @Previewable @State var files: [UnifiedSupportPickedFile] = []

    Form {
        UnifiedSupportAttachmentPicker(files: $files, maximumUploadSize: 20 * 1024 * 1024)
    }
}
