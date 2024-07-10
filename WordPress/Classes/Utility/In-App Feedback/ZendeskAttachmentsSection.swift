import SwiftUI
import Photos
import PhotosUI
import SupportProvidersSDK
import UniformTypeIdentifiers

@available(iOS 16, *)
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
                ForEach(viewModel.attachments) { attachment in
                    ZendeskAttachmentView(viewModel: attachment, onRemoveTapped: {
                        if  let item = attachment.id as? PhotosPickerItem,
                            let index = selection.firstIndex(of: item) {
                            selection.remove(at: index)
                        }
                    })
                }
            }
        }._scrollClipDisabled()
    }

    private var photosPicker: some View {
        PhotosPicker(selection: $selection, maxSelectionCount: 5, matching: .images, preferredItemEncoding: .compatible) {
            HStack {
                Image(systemName: "paperclip")
                Text(Strings.addAttachment)
            }
            .foregroundStyle(Color(uiColor: .brand))
        }
        .onChange(of: selection, perform: viewModel.process)
    }
}

@MainActor
final class ZendeskAttachmentsSectionViewModel: ObservableObject {
    @Published private(set) var attachments: [ZendeskAttachmentViewModel] = []

    @available(iOS 16, *)
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

@available(iOS 16, *)
private struct ZendeskAttachmentView: View {
    @ObservedObject var viewModel: ZendeskAttachmentViewModel
    var onRemoveTapped: () -> Void

    static let previewMaxWidth: CGFloat = 120

    var body: some View {
        Menu {
            Section {
                Button(role: .destructive, action: onRemoveTapped) {
                    Label(Strings.removeAttachment, systemImage: "trash")
                }
            } header: {
                if case .failed(let error) = viewModel.status {
                    Text(error.localizedDescription)
                }
            }
        } label: {
            contents
        }
    }

    var contents: some View {
        ZStack {
            Rectangle()
                .foregroundStyle(Color(uiColor: .secondarySystemBackground))

            viewModel.preview?
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
                EmptyView()
            }
        }
        .frame(minWidth: viewModel.preview == nil ? 100 : 44, maxWidth: ZendeskAttachmentView.previewMaxWidth)
        .frame(height: 80)
        .cornerRadius(8)
    }
}

final class ZendeskAttachmentViewModel: ObservableObject, Identifiable {
    let id: AnyHashable

    @Published private(set) var preview: Image?
    @Published private(set) var status: Status = .uploading

    private var task: Task<Void, Never>?

    var isUploaded: Bool { response != nil }

    static let attachmentSizeLimit: Int64 = 8_000_000

    var response: ZDKUploadResponse? {
        guard case .uploaded(let response) = status else { return nil }
        return response
    }

    enum Status {
        case uploading
        case failed(Error)
        case uploaded(ZDKUploadResponse)
    }

    @available(iOS 16, *)
    init(item: PhotosPickerItem) {
        self.id = item
        self.preview = preview
        self.task = Task {
            await self.process(item: item)
        }
    }

    func cancel() {
        task?.cancel()
    }

    @available(iOS 16, *)
    @MainActor private func process(item: PhotosPickerItem) async {
        status = .uploading
        do {
            let previewSize = CGSize(width: ZendeskAttachmentView.previewMaxWidth, height: ZendeskAttachmentView.previewMaxWidth)
                .scaled(by: UITraitCollection.current.displayScale)
            let contentType = preferredExportContentType(for: item)
            let (data, preview) = try await export(item, contentType: contentType, previewSize: previewSize)
            self.preview = preview

            // Checking the limit _after_ displaying the review
            guard data.count < ZendeskAttachmentViewModel.attachmentSizeLimit else {
                throw SubmitFeedbackAttachmentError.attachmentTooLarge
            }

            let response = try await ZendeskUtils.sharedInstance.uploadAttachment(data, contentType: contentType.preferredMIMEType ?? "image/jpeg")
            status = .uploaded(response)
        } catch {
            status = .failed(error)
        }
    }

    @available(iOS 16, *)
    private func preferredExportContentType(for item: PhotosPickerItem) -> UTType {
        let supportedImageTypes: Set<UTType> = [UTType.png, UTType.jpeg, UTType.gif]
        if let type = item.supportedContentTypes.first, supportedImageTypes.contains(type) {
            return type
        }
        return UTType.jpeg
    }

    @available(iOS 16, *)
    private func export(_ item: PhotosPickerItem, contentType: UTType, previewSize: CGSize) async throws -> (Data, Image) {
        guard let rawData = try await item.loadTransferable(type: Data.self) else {
            throw SubmitFeedbackAttachmentError.invalidAttachment
        }

        let exporter = MediaImageExporter(data: rawData, filename: nil, typeHint: item.supportedContentTypes.first?.identifier)
        exporter.options.maximumImageSize = 1024
        exporter.options.imageCompressionQuality = 0.7
        exporter.mediaDirectoryType = .temporary
        exporter.options.stripsGeoLocationIfNeeded = true
        exporter.options.exportImageType = contentType.identifier

        let export = try await exporter.export()
        let data = try Data(contentsOf: export.url)
        try FileManager.default.removeItem(at: export.url)

        guard let image = UIImage(data: data),
              let preview = await image.byPreparingThumbnail(ofSize: previewSize) else {
            throw SubmitFeedbackAttachmentError.invalidAttachment
        }
        return (data, Image(uiImage: preview))
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
            return String(format: format, ByteCountFormatter().string(fromByteCount: ZendeskAttachmentViewModel.attachmentSizeLimit))
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

private enum Strings {
    static let addAttachment = NSLocalizedString("zendeskAttachmentsSection.addAttachment", value: "Add Attachments", comment: "Managing Zendesk attachments")
    static let removeAttachment = NSLocalizedString("zendeskAttachmentsSection.removeAttachment", value: "Remove Attachment", comment: "Managing Zendesk attachments")
    static let unsupportedAttachmentErrorMessage = NSLocalizedString("zendeskAttachmentsSection.unsupportedAttachmentErrorMessage", value: "Unsupported attachment", comment: "Managing Zendesk attachments")
}
