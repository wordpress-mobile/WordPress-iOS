import PhotosUI
import QuickLookThumbnailing
import SwiftUI

/// The section of the reply form used to attach files.
///
/// Photos and videos come from the photo library, and everything else — documents, archives, exported logs — from
/// the file browser. Both end up in the same list.
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

    /// How many browsed files are being copied in.
    ///
    /// The file browser keeps no selection to track these against, so there's nothing to count but the files
    /// themselves.
    @State private var importingFileCount = 0

    @State private var isShowingFileBrowser = false

    @State private var loadingErrorMessage: String?

    /// Whether a file from either source is still being brought in.
    private var isLoading: Bool {
        !importing.isEmpty || importingFileCount > 0
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

    /// The two places a file can come from, offered side by side.
    ///
    /// They're separate pickers because the photo library doesn't list documents, and the file browser is a poor
    /// way to find a screenshot. Each one says what it opens, so neither needs explaining.
    private var picker: some View {
        // Read out here: the labels below are built in a nonisolated context, which can't reach the state.
        let isLoadingPhotos = !importing.isEmpty
        let isLoadingFiles = importingFileCount > 0

        return HStack(spacing: 12) {
            PhotosPicker(selection: $selection, matching: .any(of: [.images, .videos])) {
                UnifiedSupportAttachmentSourceLabel(
                    title: UnifiedSupportLocalization.attachFromPhotoLibrary,
                    systemImage: "photo.on.rectangle",
                    isLoading: isLoadingPhotos
                )
            }

            Button {
                isShowingFileBrowser = true
            } label: {
                UnifiedSupportAttachmentSourceLabel(
                    title: UnifiedSupportLocalization.attachFromFiles,
                    systemImage: "folder",
                    isLoading: isLoadingFiles
                )
            }
            // Left to the label, which is already drawn as a button.
            .buttonStyle(.plain)
        }
        // Anything the support team can be sent is worth offering, so the browser isn't narrowed to a list of
        // types: a crash report or an exported database is as useful as a screenshot. `data` is every type
        // that is a file, which leaves out the one thing there's no sending — a folder.
        .fileImporter(
            isPresented: $isShowingFileBrowser,
            allowedContentTypes: [.data],
            allowsMultipleSelection: true
        ) { result in
            switch result {
            case .success(let urls):
                imports.start {
                    await load(browsed: urls)
                }
            case .failure(let error):
                // Backing out of the browser isn't a failure worth a message.
                guard !error.isUnifiedSupportCancellation else {
                    return
                }
                loadingErrorMessage = error.unifiedSupportMessage
            }
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

        if !isLoading {
            loadingErrorMessage = nil
        }
        importing.formUnion(newItems)
        isImporting = true
        defer {
            importing.subtract(newItems)
            isImporting = isLoading
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

    /// Brings in the files picked from the file browser.
    ///
    /// Unlike the photo library, the browser remembers no selection, so each pick is only ever an addition and
    /// there's nothing to take back off the list here.
    private func load(browsed urls: [URL]) async {
        guard !urls.isEmpty else {
            return
        }

        if !isLoading {
            loadingErrorMessage = nil
        }
        importingFileCount += urls.count
        isImporting = true
        defer {
            importingFileCount -= urls.count
            isImporting = isLoading
        }

        for url in urls {
            do {
                // Copying a file the size of a video would block the form for as long as it takes.
                //
                // The coordination is held out here so leaving the form can stop a fetch still waiting on
                // iCloud: a detached task inherits no cancellation, and awaiting one isn't a cancellation
                // point either, so nothing else would interrupt the download.
                let coordination = UnifiedSupportFileCoordination()
                let copy = Task.detached(priority: .userInitiated) {
                    try UnifiedSupportAttachmentStorage.store(securityScoped: url, coordination: coordination)
                }
                let file = try await withTaskCancellationHandler {
                    try await copy.value
                } onCancel: {
                    coordination.cancel()
                }

                // The form can close while a file is being copied, which leaves the reply it was picked for
                // gone, and nowhere to put it. The files queued behind this one have nowhere to go either, so
                // they're left uncopied rather than copied and thrown away one by one.
                guard !Task.isCancelled else {
                    UnifiedSupportAttachmentStorage.delete(file)
                    break
                }
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

/// One of the places an attachment can be picked from, drawn as a button.
private struct UnifiedSupportAttachmentSourceLabel: View {

    let title: String
    let systemImage: String

    /// Whether this source is still bringing a file in, which replaces its icon with a spinner.
    let isLoading: Bool

    var body: some View {
        VStack(spacing: 6) {
            if isLoading {
                ProgressView()
                    .tint(Color.accentColor)
            } else {
                Image(systemName: systemImage)
            }

            Text(title)
                .font(.subheadline)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background(Color.accentColor.opacity(0.1))
        .foregroundStyle(Color.accentColor)
        .clipShape(RoundedRectangle(cornerRadius: 8))
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

/// A preview of a picked file, generated by QuickLook so it works for images, videos and documents alike.
private struct UnifiedSupportAttachmentThumbnail: View {

    let file: UnifiedSupportPickedFile

    private static let size = CGSize(width: 80, height: 80)

    @State private var image: UIImage?

    /// Whether QuickLook has been asked, which is what separates a file still being previewed from one that has
    /// no preview to offer.
    @State private var didGenerateThumbnail = false

    var body: some View {
        Group {
            if let image {
                Image(uiImage: image)
                    .resizable()
                    .aspectRatio(contentMode: .fill)
            } else {
                placeholder
            }
        }
        .frame(width: Self.size.width, height: Self.size.height)
        .clipShape(RoundedRectangle(cornerRadius: 8))
        .accessibilityLabel(file.filename)
        .task(id: file.id) {
            image = await generateThumbnail()
            didGenerateThumbnail = true
        }
    }

    /// Names the file once it's clear no preview is coming: the archives and logs QuickLook can't draw would
    /// otherwise all be the same anonymous tile.
    private var placeholder: some View {
        Color(.systemGray5)
            .overlay {
                VStack(spacing: 4) {
                    Image(systemName: "doc")

                    if didGenerateThumbnail {
                        Text(file.filename)
                            .font(.caption2)
                            .lineLimit(2)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, 4)
                    }
                }
                .foregroundStyle(.secondary)
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
