import PhotosUI
import QuickLookThumbnailing
import SwiftUI

/// The section of the reply form used to attach images and videos.
///
/// Files are taken up to the upload limit, in the order they were picked. The ones that don't fit are listed, so the
/// user can make room for them by removing another file.
struct UnifiedSupportAttachmentPicker: View {

    @Binding var files: [UnifiedSupportPickedFile]

    /// Whether files are still being brought in, so the form doesn't send a reply without them.
    @Binding var isImporting: Bool

    /// The imports started here, held by the form so that closing it stops them.
    let imports: UnifiedSupportAttachmentImports

    let maximumUploadSize: UInt64

    @State private var selection: [PhotosPickerItem] = []

    /// The picker item each file was loaded from, used to keep the picker and the list in sync.
    @State private var items: [UUID: PhotosPickerItem] = [:]

    /// The items being imported, claimed before the import starts.
    ///
    /// An item is only in `items` once it has finished importing, so two imports running at the same time would
    /// otherwise both take the same item for a new one.
    @State private var importing: Set<PhotosPickerItem> = []

    @State private var loadingErrorMessage: String?

    private var isLoading: Bool {
        !importing.isEmpty
    }

    var body: some View {
        // Worked out once per pass: every file is measured against the limit, and the gallery asks about each of
        // them again.
        let validation = UnifiedSupportAttachmentValidator(maximumUploadSize: maximumUploadSize).validate(files)

        Section {
            Text(UnifiedSupportLocalization.attachmentsDescription)
                .font(.body)
                .foregroundStyle(.secondary)

            if let loadingErrorMessage {
                ErrorView(title: UnifiedSupportLocalization.attachmentsFailedTitle, message: loadingErrorMessage)
            }

            if !files.isEmpty {
                gallery(validation)
            }

            // Nothing to say while everything fits: the user didn't ask to be kept posted on a budget.
            if !validation.skipped.isEmpty {
                overflow(validation)
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
            imports.start {
                await load(newSelection)
            }
        }
    }

    private func gallery(_ validation: UnifiedSupportAttachmentValidator.Result) -> some View {
        let skipped = Set(validation.skipped.map(\.id))

        return ScrollView(.horizontal, showsIndicators: false) {
            LazyHStack(spacing: 12) {
                ForEach(files) { file in
                    ZStack(alignment: .topTrailing) {
                        UnifiedSupportAttachmentThumbnail(file: file)
                            .opacity(skipped.contains(file.id) ? 0.4 : 1)

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

    /// Shown only once the upload limit is in the way, which is the only point at which there's anything to say.
    ///
    /// The bar is full by definition here. Which files are left out is read off the gallery, where they're the
    /// faded ones.
    private func overflow(_ validation: UnifiedSupportAttachmentValidator.Result) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            ProgressView(value: 1)
                .tint(Color(.systemRed))
                // The line underneath says the same thing in words.
                .accessibilityHidden(true)

            Text(overflowMessage(validation))
                .font(.caption)
                .foregroundStyle(Color(.systemRed))
        }
    }

    private func overflowMessage(_ validation: UnifiedSupportAttachmentValidator.Result) -> String {
        // Nothing was accepted, so every file is over the limit on its own and no amount of removing helps.
        guard !validation.accepted.isEmpty else {
            return validation.skipped.count == 1
                ? UnifiedSupportLocalization.attachmentTooLarge
                : UnifiedSupportLocalization.attachmentsTooLarge
        }

        return String.localizedStringWithFormat(
            UnifiedSupportLocalization.attachmentsPartial,
            validation.accepted.count,
            validation.accepted.count + validation.skipped.count
        )
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

        let claimed = Set(items.values).union(importing)
        let newItems = newSelection.filter { !claimed.contains($0) }
        guard !newItems.isEmpty else {
            return
        }

        if importing.isEmpty {
            loadingErrorMessage = nil
        }
        importing.formUnion(newItems)
        isImporting = true
        defer {
            importing.subtract(newItems)
            isImporting = !importing.isEmpty
        }

        for item in newItems {
            do {
                guard let file = try await item.loadTransferable(type: UnifiedSupportPickedFile.self) else {
                    continue
                }
                // The form can close, or the item come off the picker, while the file is being brought in.
                // Either way the reply it was picked for is gone, and so is anywhere to put it.
                guard !Task.isCancelled, selection.contains(item) else {
                    UnifiedSupportAttachmentStorage.delete(file)
                    continue
                }
                items[file.id] = item
                files.append(file)
            } catch {
                // Closing the form cancels the import, which isn't a failure worth a message.
                guard !Task.isCancelled, !error.isUnifiedSupportCancellation else {
                    return
                }
                loadingErrorMessage = error.unifiedSupportMessage
            }
        }
    }
}

/// The imports running for a reply form.
///
/// Bringing a file in outlives the view that started it, so the form has to stop the ones still running when it
/// closes: a file that arrives afterwards would attach itself to a reply the user threw away.
@MainActor
final class UnifiedSupportAttachmentImports {

    private var tasks: [UUID: Task<Void, Never>] = [:]

    /// Runs an import that `cancelAll()` can stop.
    func start(_ work: @escaping @MainActor () async -> Void) {
        let id = UUID()
        tasks[id] = Task { [weak self] in
            await work()
            self?.tasks[id] = nil
        }
    }

    /// Stops the imports still running, so their files can't land in a reply the user has closed.
    func cancelAll() {
        for task in tasks.values {
            task.cancel()
        }
        tasks.removeAll()
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

    @Previewable @State var isImporting = false

    Form {
        UnifiedSupportAttachmentPicker(
            files: $files,
            isImporting: $isImporting,
            imports: UnifiedSupportAttachmentImports(),
            maximumUploadSize: 20 * 1024 * 1024
        )
    }
}
