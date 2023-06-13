import Foundation
import SwiftUI
import Combine
import SVProgressHUD

struct SiteSettingsView: View {
    @ObservedObject private var blog: Blog
    @ObservedObject private var settings: BlogSettings

    @StateObject private var viewModel: SiteSettingsViewModel

    @SwiftUI.Environment(\.presentationMode) private var presentationMode

    init(blog: Blog) {
        self.blog = blog
        self.settings = blog.settings ?? BlogSettings(context: ContextManager.shared.mainContext) // Right-side should never happen
        self._viewModel = StateObject(wrappedValue: SiteSettingsViewModel(blog: blog))
    }

    var body: some View {
        List {
            sections
        }
        .listStyle(.insetGrouped)
        .onReceive(viewModel.onDismissableError) {
            SVProgressHUD.showDismissibleError(withStatus: $0)
        }
        .backport.refreshable {
            await viewModel.refresh()
        }
        .onAppear {
            Task { await viewModel.refresh() }
        }
        .navigationTitle(Strings.title)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar { toolbar }
    }

    private var toolbar: some ToolbarContent {
        ToolbarItem(placement: .navigationBarTrailing) {
            if presentationMode.wrappedValue.isPresented {
                closeButton
            }
        }
    }

    // MARK: - Sections

    private var sections: some View {
        Section(header: Text(Strings.Sections.general)) {
            siteTitleRow
            taglineRow
            addressRow
        }
    }

    // MARK: - Sections (General)

    private var siteTitleRow: some View {
        withAdminNavigationLink(destination: {
            SettingsTextEditView(
                value: settings.name,
                placeholder: Strings.General.siteTitlePlaceholder,
                onCommit: viewModel.updateSiteTitle
            )
            .navigationTitle(Strings.General.siteTitle)
        }, content: {
            SettingsCell(
                title: Strings.General.siteTitle,
                value: settings.name,
                placeholder: Strings.General.siteTitlePlaceholder
            )
        })
    }

    private var taglineRow: some View {
        withAdminNavigationLink(destination: {
            SettingsTextEditView(
                value: settings.tagline,
                placeholder: Strings.General.taglineEditorPlaceholder,
                hint: Strings.General.taglineEditorHint,
                onCommit: viewModel.updateTagline
            )
            .navigationTitle(Strings.General.tagline)
        }, content: {
            SettingsCell(title: Strings.General.tagline, value: settings.tagline)
        })
    }

    private var addressRow: some View {
        SettingsCell(title: Strings.General.address, value: blog.url)
            .contextMenu {
                Button(Strings.General.copyAddress) {
                    UIPasteboard.general.url = blog.url.flatMap(URL.init)
                }
            }
    }

    // MARK: - Helpers

    @ViewBuilder
    private func withAdminNavigationLink<T: View, U: View>(
        @ViewBuilder destination: () -> T,
        @ViewBuilder content: () -> U
    ) -> some View {
        if blog.isAdmin {
            NavigationLink(destination: destination(), label: content)
        } else {
            content()
        }
    }

    private var closeButton: some View {
        Button(action: { presentationMode.wrappedValue.dismiss() }) {
            Text(Strings.done)
                .font(.body.weight(.medium))
                .foregroundColor(Color.primary)
        }
    }
}

private struct SettingsCell: View {
    let title: String
    let value: String?
    var placeholder: String?

    var body: some View {
        HStack {
            Text(title)
                .layoutPriority(1)
            Spacer()
            Text(value ?? (placeholder ?? ""))
                .foregroundColor(.secondary)
        }
        .lineLimit(1)
    }
}

private struct SettingsTextEditView: UIViewControllerRepresentable {
    let value: String?
    let placeholder: String
    var hint: String?
    let onCommit: ((String)) -> Void

    func makeUIViewController(context: Context) -> SettingsTextViewController {
        let viewController = SettingsTextViewController(text: value ?? "", placeholder: placeholder, hint: hint ?? "")
        viewController.onValueChanged = onCommit
        return viewController
    }

    func updateUIViewController(_ uiViewController: SettingsTextViewController, context: Context) {
        // Do nothing
    }
}

private extension SiteSettingsView {
    enum Strings {
        static let title = NSLocalizedString("siteSettings.title", value: "Settings", comment: "Title for screen that allows configuration of your blog/site settings.")
        static let done = NSLocalizedString("siteSettings.done", value: "Done", comment: "Label for Done button")

        enum Sections {
            static let general = NSLocalizedString("siteSettings.general.title", value: "General", comment: "Title for the general section in site settings screen")
        }

        enum General {
            static let siteTitle = NSLocalizedString("siteSettings.general.siteTitle", value: "Site Title", comment: "Label for site title blog setting")
            static let siteTitlePlaceholder = NSLocalizedString("siteSettings.general.siteTitlePlaceholder", value: "A title for the site", comment: "Placeholder text for the title of a site")
            static let tagline = NSLocalizedString("Tagline", comment: "Label for tagline blog setting")
            static let taglinePlaceholder = NSLocalizedString("Explain what this site is about.", comment: "Placeholder text for the tagline of a site")
            static let taglineEditorPlaceholder = NSLocalizedString("Explain what this site is about.", comment: "Placeholder text for the tagline of a site")
            static let taglineEditorHint = NSLocalizedString("In a few words, explain what this site is about.", comment: "Explain what is the purpose of the tagline")
            static let address = NSLocalizedString("Address", comment: "Label for url blog setting")
            static let copyAddress = NSLocalizedString("siteSettings.general.copyAddress", value: "Copy Address", comment: "Button title to copy site address")
        }
    }
}
