import SwiftUI
import UniformTypeIdentifiers
import WordPressAPI

struct MediaDetailView: View {
    @StateObject var viewModel: MediaDetailViewModel
    @State private var isConfirmingDelete = false
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        Form {
            Section {
                EmptyView()
            } header: {
                MediaPreviewHeader(display: viewModel.display)
                    .frame(maxWidth: .infinity)
                    .listRowInsets(EdgeInsets())
                    .textCase(nil)
            }

            editableFieldsSection

            metadataSection
        }
        .navigationTitle(viewModel.displayValue(for: .title))
        .navigationBarTitleDisplayMode(.inline)
        .toolbar { detailToolbar }
        .alert(Strings.detailUnableToSaveTitle, isPresented: saveErrorBinding, presenting: viewModel.saveErrorMessage) {
            _ in
            Button(Strings.commonOK, role: .cancel) { viewModel.saveErrorMessage = nil }
        } message: {
            Text($0)
        }
        .alert(
            Strings.detailUnableToDeleteTitle,
            isPresented: deleteErrorBinding,
            presenting: viewModel.deleteErrorMessage
        ) { _ in
            Button(Strings.commonOK, role: .cancel) { viewModel.deleteErrorMessage = nil }
        } message: {
            Text($0)
        }
        .alert(
            Strings.detailUnableToShareTitle,
            isPresented: shareErrorBinding,
            presenting: viewModel.shareErrorMessage
        ) { _ in
            Button(Strings.commonOK, role: .cancel) { viewModel.shareErrorMessage = nil }
        } message: {
            Text($0)
        }
        .alert(Strings.detailDeleteConfirmation, isPresented: $isConfirmingDelete) {
            Button(Strings.detailDeleteAction, role: .destructive) {
                Task { await viewModel.delete() }
            }
            Button(Strings.commonCancel, role: .cancel) {}
        }
        .sheet(item: $viewModel.sharePayload) { payload in
            ShareSheetRepresentable(urls: payload.urls) { completed in
                viewModel.reportShareDismissed(payload, completed: completed)
            }
            .onAppear { viewModel.shareSheetDidPresent() }
        }
        .onChange(of: viewModel.shouldPop) { _, shouldPop in
            if shouldPop { dismiss() }
        }
        .task { viewModel.onAppear() }
        // The in-flight guards keep anything from covering this screen while
        // a share prepares, so disappearance means a real pop (or a tab
        // switch, which is an acceptable reason to cancel too). Besides
        // cancelling, the VM releases a share payload whose sheet never
        // presented, closing the pop-during-download temp-file leak.
        .onDisappear { viewModel.viewDidDisappear() }
    }

    @ViewBuilder private var editableFieldsSection: some View {
        Section {
            ForEach(viewModel.visibleEditableFields, id: \.self) { field in
                editableRow(for: field)
            }
        }
    }

    @ViewBuilder private func editableRow(for field: MediaEditableField) -> some View {
        if viewModel.isEditable(field) {
            // UIKit-bridge push instead of SwiftUI NavigationLink. The
            // detail screen is hosted on the outer UINavigationController
            // (no NavigationStack ancestor), so NavigationLink wouldn't
            // resolve a destination. The VM constructs the editor's
            // UIHostingController and asks the injected navigator to push.
            // We render the disclosure chevron manually since the
            // NavigationLink affordance is gone.
            Button {
                viewModel.pushFieldEditor(for: field)
            } label: {
                HStack {
                    LabeledContent(field.localizedTitle, value: viewModel.displayValue(for: field))
                    Image(systemName: "chevron.forward")
                        .font(.footnote.weight(.semibold))
                        .foregroundStyle(.tertiary)
                }
            }
            .buttonStyle(.plain)
        } else {
            LabeledContent(field.localizedTitle, value: viewModel.displayValue(for: field))
                .foregroundStyle(.secondary)
        }
    }

    @ViewBuilder private var metadataSection: some View {
        Section {
            if !viewModel.display.sourceUrl.isEmpty {
                // Custom HStack — `LabeledContent` collapses to a vertical
                // stack when its trailing content has tap behaviour, so the
                // label-on-top / value-below layout we got with Button or
                // Link in the trailing slot doesn't match V1. Manual HStack
                // gives label-on-left + truncated-link-on-right reliably.
                HStack(spacing: 8) {
                    Text(Strings.detailMetadataURL)
                    Text(viewModel.display.sourceUrl)
                        .lineLimit(1)
                        .truncationMode(.middle)
                        // Dimmed while an operation is in flight; the VM
                        // guard in `openSourceURL` is the functional gate.
                        .foregroundStyle(
                            viewModel.isAnyOperationInFlight ? AnyShapeStyle(.secondary) : AnyShapeStyle(.tint)
                        )
                        .frame(maxWidth: .infinity, alignment: .trailing)
                }
                .contentShape(Rectangle())
                .onTapGesture { viewModel.openSourceURL() }
                .accessibilityElement(children: .combine)
                .accessibilityAddTraits(.isLink)
                .accessibilityAction { viewModel.openSourceURL() }
            }
            LabeledContent(Strings.detailMetadataFileName, value: fileName)
            LabeledContent(Strings.detailMetadataFileType, value: fileType)
            if let size = fileSizeString {
                LabeledContent(Strings.detailMetadataFileSize, value: size)
            }
            if let dims = dimensionsString {
                LabeledContent(Strings.detailMetadataDimensions, value: dims)
            }
            LabeledContent(Strings.detailMetadataUploaded, value: uploadedString)
            LabeledContent(Strings.detailMetadataMimeType, value: viewModel.display.mimeType.nonEmptyOr("—"))
        } footer: {
            Text(String.localizedStringWithFormat(Strings.detailIdFooter, viewModel.display.id))
                .frame(maxWidth: .infinity, alignment: .center)
                .padding(.top, 20)
        }
    }

    @ToolbarContentBuilder private var detailToolbar: some ToolbarContent {
        if viewModel.capabilities.supportsDeletion {
            ToolbarItem(placement: .topBarTrailing) {
                Button {
                    isConfirmingDelete = true
                } label: {
                    Image(systemName: "trash").accessibilityLabel(Strings.detailDeleteAction)
                }
                .disabled(!viewModel.isTrashEnabled)
            }
        }
        ToolbarItem(placement: .topBarTrailing) {
            if viewModel.isSharing {
                // The spinner replaces the share button while the download
                // prepares; tapping it cancels the share.
                Button {
                    viewModel.cancelShare()
                } label: {
                    ProgressView()
                }
                .accessibilityLabel(Strings.detailShareCancelAccessibility)
            } else {
                Button {
                    viewModel.share()
                } label: {
                    Image(systemName: "square.and.arrow.up").accessibilityLabel(Strings.commonShare)
                }
                .disabled(!viewModel.isShareEnabled)
            }
        }
    }

    private var fileName: String {
        URL(string: viewModel.display.sourceUrl)?.lastPathComponent.nonEmptyOr("—") ?? "—"
    }

    private var fileType: String {
        let urlExt = URL(string: viewModel.display.sourceUrl)?.pathExtension ?? ""
        if !urlExt.isEmpty { return urlExt.uppercased() }
        if let mimeExt = UTType(mimeType: viewModel.display.mimeType)?.preferredFilenameExtension {
            return mimeExt.uppercased()
        }
        return "—"
    }

    private var fileSizeString: String? {
        guard let payload = viewModel.display.mediaDetails.parseAsMimeType(mimeType: viewModel.display.mimeType) else {
            return nil
        }
        let bytes: UInt64 = {
            switch payload {
            case .image(let d): return d.fileSize
            case .video(let d): return d.fileSize
            case .audio(let d): return d.fileSize
            case .document(let d): return d.fileSize
            }
        }()
        let formatter = ByteCountFormatter()
        return formatter.string(fromByteCount: Int64(bytes))
    }

    private var dimensionsString: String? {
        guard let payload = viewModel.display.mediaDetails.parseAsMimeType(mimeType: viewModel.display.mimeType) else {
            return nil
        }
        switch payload {
        case .image(let d): return "\(d.width) × \(d.height)"
        case .video(let d): return "\(d.width) × \(d.height)"
        case .audio, .document: return nil
        }
    }

    private var uploadedString: String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .none
        return formatter.string(from: viewModel.display.dateGmt)
    }

    private var saveErrorBinding: Binding<Bool> {
        Binding(get: { viewModel.saveErrorMessage != nil }, set: { if !$0 { viewModel.saveErrorMessage = nil } })
    }
    private var deleteErrorBinding: Binding<Bool> {
        Binding(get: { viewModel.deleteErrorMessage != nil }, set: { if !$0 { viewModel.deleteErrorMessage = nil } })
    }
    private var shareErrorBinding: Binding<Bool> {
        Binding(get: { viewModel.shareErrorMessage != nil }, set: { if !$0 { viewModel.shareErrorMessage = nil } })
    }
}

private extension String {
    func nonEmptyOr(_ fallback: String) -> String { isEmpty ? fallback : self }
}
