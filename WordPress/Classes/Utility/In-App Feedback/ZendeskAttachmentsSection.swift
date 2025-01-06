import SwiftUI
import Photos
import PhotosUI
import SupportProvidersSDK
import UniformTypeIdentifiers
import QuickLook
import QuickLookThumbnailing
import AVFoundation

struct ZendeskAttachmentsSection: View {
    @ObservedObject var viewModel: ZendeskAttachmentsSectionViewModel

    @State private var selection: [PhotosPickerItem] = []
    @State private var previewURL: URL?

    var body: some View {
        Section {
            VStack(alignment: .leading, spacing: 16) {
                if !viewModel.attachments.isEmpty {
                    attachmentsStack
                }
                photosPicker
            }
            .padding(.vertical, 8)
        }
        .listRowBackground(Color.clear)
        .onDisappear(perform: viewModel.onDisappear)
    }

    private var attachmentsStack: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                ForEach(viewModel.attachments, content: makeView)
            }
        }._scrollClipDisabled()
    }

    private func makeView(for attachment: ZendeskAttachmentViewModel) -> some View {
        ZendeskAttachmentView(viewModel: attachment) {
            Section {
                Button(role: .destructive, action: { removeAttachment(attachment) }) {
                    Label(Strings.removeAttachment, systemImage: "trash")
                }
            } header: {
                if case .failed(let error) = attachment.status {
                    Text(error.localizedDescription)
                }
            }
        }
    }

    private func removeAttachment(_ attachment: ZendeskAttachmentViewModel) {
        if  let item = attachment.id as? PhotosPickerItem,
            let index = selection.firstIndex(of: item) {
            selection.remove(at: index)
        }
    }

    private var photosPicker: some View {
        PhotosPicker(selection: $selection, maxSelectionCount: 5, preferredItemEncoding: .compatible) {
            HStack {
                Image(systemName: "paperclip")
                Text(Strings.addAttachment)
            }
            .foregroundStyle(Color(uiColor: UIAppColor.primary))
        }
        .onChange(of: selection, perform: viewModel.process)
    }
}

@MainActor
final class ZendeskAttachmentsSectionViewModel: ObservableObject {
    @Published private(set) var attachments: [ZendeskAttachmentViewModel] = []

    func process(selection: [PhotosPickerItem]) {
        var previous = Dictionary(uniqueKeysWithValues: attachments.map { ($0.id, $0) })
        self.attachments = selection.map {
            previous.removeValue(forKey: $0) ?? ZendeskAttachmentViewModel(item: $0)
        }
        previous.values.forEach { $0.cancel() } // Cancel remaining
    }

    func onDisappear() {
        attachments.forEach { $0.cancel() }
    }
}

private struct ZendeskAttachmentView<Actions: View>: View {
    @ObservedObject var viewModel: ZendeskAttachmentViewModel
    @ViewBuilder var actions: () -> Actions

    var body: some View {
        Menu {
            actions() // Reloading it here because this view observes the ViewModel
        } label: {
            contents
        }
    }

    var contents: some View {
        ZStack {
            Rectangle()
                .foregroundStyle(Color(uiColor: .secondarySystemBackground))

            viewModel.thumbnail?
                .resizable()
                .aspectRatio(contentMode: .fill)

            switch viewModel.status {
            case .uploading:
                Rectangle()
                    .foregroundStyle(Color(uiColor: .systemBackground).opacity(0.75))
                ProgressView()
            case .failed:
                Rectangle()
                    .foregroundStyle(Color(uiColor: .systemBackground).opacity(0.75))
                Image(systemName: "exclamationmark.circle.fill")
                    .foregroundStyle(.white, .red)
                    .font(.system(size: 22))
            case .uploaded:
                if let duration = viewModel.export?.duration, duration > 0 {
                    Image(systemName: "play.circle.fill")
                        .font(.system(size: 20))
                        .foregroundStyle(Color(.secondaryLabel), Color(.secondarySystemBackground))
                }
            }
        }
        .frame(minWidth: viewModel.thumbnail == nil ? 100 : 44, maxWidth: Constants.thumbnailMaxWidth)
        .frame(height: 80)
        .cornerRadius(8)
    }
}

final class ZendeskAttachmentViewModel: ObservableObject, Identifiable {
    let id: AnyHashable

    @Published private(set) var thumbnail: Image?
    @Published private(set) var export: MediaExport?
    @Published private(set) var status: Status = .uploading

    private var task: Task<Void, Never>?

    var isUploaded: Bool { response != nil }

    var response: ZDKUploadResponse? {
        guard case .uploaded(let response) = status else { return nil }
        return response
    }

    enum Status {
        case uploading
        case failed(Error)
        case uploaded(ZDKUploadResponse)
    }

    private let directory = MediaDirectory.temporary(id: UUID())

    init(item: PhotosPickerItem) {
        self.id = item
        self.thumbnail = thumbnail
        self.task = Task {
            await self.process(item: item)
        }
    }

    deinit {
        try? FileManager.default.removeItem(at: directory.url)
    }

    func cancel() {
        task?.cancel()
    }

    @MainActor private func process(item: PhotosPickerItem) async {
        status = .uploading
        do {
            let export = try await export(item)
            self.export = export

            let thumbnailSize = CGSize(width: Constants.thumbnailMaxWidth, height: Constants.thumbnailMaxWidth)
                .scaled(by: UITraitCollection.current.displayScale)
            self.thumbnail = try? await makeThumbnail(for: export, thumbnailSize: thumbnailSize)

            // Checking the limit _after_ displaying the preview
            guard (export.fileSize ?? 0) < Constants.attachmentSizeLimit else {
                throw SubmitFeedbackAttachmentError.attachmentTooLarge
            }
            status = .uploaded(try await upload(export))
        } catch {
            status = .failed(error)
        }
    }

    private func export(_ item: PhotosPickerItem) async throws -> MediaExport {
        guard let rawData = try await item.loadTransferable(type: Data.self) else {
            throw SubmitFeedbackAttachmentError.invalidAttachment
        }
        let contentType = item.supportedContentTypes.first
        let itemProvider = NSItemProvider(item: rawData as NSData, typeIdentifier: contentType?.identifier)
        let exporter = ItemProviderMediaExporter(provider: itemProvider)
        exporter.mediaDirectoryType = directory
        exporter.imageOptions = Constants.imageExportOptions
        exporter.videoOptions = Constants.videoExportOptions
        return try await exporter.export()
    }

    private func makeThumbnail(for export: MediaExport, thumbnailSize: CGSize) async throws -> Image {
        let thumbnailRequest = QLThumbnailGenerator.Request(fileAt: export.url, size: thumbnailSize, scale: 1, representationTypes: .all)
        let preview = try await QLThumbnailGenerator().generateBestRepresentation(for: thumbnailRequest)
        return Image(uiImage: preview.uiImage)
    }

    private func upload(_ export: MediaExport) async throws -> ZDKUploadResponse {
        let contentType = UTType(filenameExtension: export.url.pathExtension) ?? .data
        let data = try Data(contentsOf: export.url)
        return try await ZendeskUtils.sharedInstance.uploadAttachment(data, contentType: contentType.preferredMIMEType ?? "image/jpeg")
    }
}

private enum SubmitFeedbackAttachmentError: Error, LocalizedError {
    case invalidAttachment
    case attachmentTooLarge

    var errorDescription: String? {
        switch self {
        case .invalidAttachment:
            return NSLocalizedString("zendeskAttachmentsSection.unsupportedAttachmentErrorMessage", value: "Unsupported attachment", comment: "Managing Zendesk attachments")
        case .attachmentTooLarge:
            let format = NSLocalizedString("zendeskAttachmentsSection.unsupportedAttachmentErrorMessage", value: "The attachment is too large. The maximum allowed size is %@.", comment: "Managing Zendesk attachments")
            return String(format: format, ByteCountFormatter().string(fromByteCount: Constants.attachmentSizeLimit))
        }
    }
}

private extension View {
    @ViewBuilder
    func _scrollClipDisabled() -> some View {
        if #available(iOS 17, *) {
            self.scrollClipDisabled()
        } else {
            self
        }
    }
}

private enum Constants {
    static let thumbnailMaxWidth: CGFloat = 120

    static let attachmentSizeLimit: Int64 = 32_000_000

    static let imageExportOptions: MediaImageExporter.Options =  {
        var options = MediaImageExporter.Options()
        options.maximumImageSize = 1024
        options.imageCompressionQuality = 0.7
        options.stripsGeoLocationIfNeeded = true
        return options
    }()

    static let videoExportOptions: MediaVideoExporter.Options = {
        var options = MediaVideoExporter.Options()
        options.exportPreset = AVAssetExportPreset1280x720
        options.durationLimit = 5 * 60
        options.stripsGeoLocationIfNeeded = true
        return options
    }()
}

private enum Strings {
    static let addAttachment = NSLocalizedString("zendeskAttachmentsSection.addAttachment", value: "Add Attachments", comment: "Managing Zendesk attachments")
    static let removeAttachment = NSLocalizedString("zendeskAttachmentsSection.removeAttachment", value: "Remove Attachment", comment: "Managing Zendesk attachments")
    static let unsupportedAttachmentErrorMessage = NSLocalizedString("zendeskAttachmentsSection.unsupportedAttachmentErrorMessage", value: "Unsupported attachment", comment: "Managing Zendesk attachments")
}
