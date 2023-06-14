import Foundation
import SwiftUI
import Combine
import SVProgressHUD

final class NewSiteSettingsViewController: UIHostingController<SiteSettingsView> {
    init(blog: Blog) {
        super.init(rootView: SiteSettingsView(blog: blog))
    }

    @MainActor required dynamic init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        if presentingViewController != nil {
            navigationItem.rightBarButtonItem = UIBarButtonItem(barButtonSystemItem: .done, target: self, action: #selector(dimissSelf))
        }
    }

    @objc private func dimissSelf() {
        presentingViewController?.dismiss(animated: true)
    }
}

struct SiteSettingsView: View {
    @ObservedObject private var blog: Blog
    @ObservedObject private var settings: BlogSettings

    @StateObject private var viewModel: SiteSettingsViewModel

    init(blog: Blog) {
        self.blog = blog
        self.settings = blog.settings ?? BlogSettings(context: ContextManager.shared.mainContext) // Right-side should never happen
        self._viewModel = StateObject(wrappedValue: SiteSettingsViewModel(blog: blog))
    }

    var body: some View {
        Form {
            sections
        }
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
    }

    // MARK: - Sections

    private var sections: some View {
        Section(header: Text(Strings.Sections.general)) {
            siteTitleRow
            taglineRow
            addressRow
            if blog.supportsSiteManagementServices() {
                privacyRow
                languageRow
            }
            if blog.supports(.wpComRESTAPI) {
                timezoneRow
            }
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

    private var privacyRow: some View {
        SettingsPicker(
            title: Strings.General.privacy,
            selection: $blog.siteVisibility,
            values: SiteVisibility.eligiblePickerValues(for: blog)
        )
        .editable(blog.isAdmin)
        .onChange(perform: viewModel.updateVisibility)
    }

    private var languageRow: some View {
        withAdminNavigationLink(destination: {
            LanguagePickerView(blog: blog, onChange: viewModel.updateLanguage)
                .navigationTitle(Strings.General.language)
        }, content: {
            let language = WordPressComLanguageDatabase().nameForLanguageWithId(settings.languageID.intValue)
            SettingsCell(title: Strings.General.language, value: language)
        })
    }

    private var timezoneRow: some View {
        withAdminNavigationLink(destination: {
            TimezoneSelectorView(value: viewModel.timezoneValue, onChange: viewModel.updateTimezone)
        }, content: {
            SettingsCell(title: Strings.General.timezone, value: viewModel.timezoneLabel)
        })
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
            static let tagline = NSLocalizedString("siteSettings.general.tagline", value: "Tagline", comment: "Label for tagline blog setting")
            static let taglinePlaceholder = NSLocalizedString("siteSettings.general.taglinePlaceholder", value: "Explain what this site is about.", comment: "Placeholder text for the tagline of a site")
            static let taglineEditorPlaceholder = NSLocalizedString("siteSettings.general.taglineEditorPlaceholder", value: "Explain what this site is about.", comment: "Placeholder text for the tagline of a site")
            static let taglineEditorHint = NSLocalizedString("siteSettings.general.taglineEditorHint", value: "In a few words, explain what this site is about.", comment: "Explain what is the purpose of the tagline")
            static let address = NSLocalizedString("siteSettings.general.address", value: "Address", comment: "Label for url blog setting")
            static let copyAddress = NSLocalizedString("siteSettings.general.copyAddress", value: "Copy Address", comment: "Button title to copy site address")
            static let privacy = NSLocalizedString("siteSettings.general.privacy", value: "Privacy", comment: "Label for the privacy setting")
            static let language = NSLocalizedString("siteSettings.general.language", value: "Language", comment: "Label for the privacy setting")
            static let timezone = NSLocalizedString("siteSettings.general.timeone", value: "Time Zone", comment: "Label for the timezone setting")
        }
    }
}
