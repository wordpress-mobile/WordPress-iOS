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

    private var sections: some View {
        Section(header: Text(Strings.Sections.general)) {
            siteTitleRow
        }
    }

    // MARK: - General

    private var siteTitleRow: some View {
        withAdminNavigationLink(destination: {
            SettingsTextEditView(
                value: settings.name,
                placeholder: Strings.General.siteTitlePlaceholder,
                onCommit: viewModel.updateSiteTitle
            )
            .navigationTitle(Strings.General.siteTitle)
        }) {
            SettingsCell(title: Strings.General.siteTitle, value: settings.name ?? Strings.General.siteTitlePlaceholder)
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
    let value: String

    var body: some View {
        HStack {
            Text(title)
                .layoutPriority(1)
            Spacer()
            Text(value)
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
        static let title = NSLocalizedString("Settings", comment: "Title for screen that allows configuration of your blog/site settings.")
        static let done = NSLocalizedString("Done", comment: "Label for Done button")

        enum Sections {
            static let general = NSLocalizedString("General", comment: "Title for the general section in site settings screen")
        }

        enum General {
            static let siteTitle = NSLocalizedString("Site Title", comment: "Label for site title blog setting")
            static let siteTitlePlaceholder = NSLocalizedString("A title for the site", comment: "Placeholder text for the title of a site")
        }
    }
}
