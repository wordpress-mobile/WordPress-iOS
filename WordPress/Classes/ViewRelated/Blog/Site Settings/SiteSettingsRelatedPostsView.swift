import Foundation
import SwiftUI
import SVProgressHUD
import WordPressShared

struct RelatedPostsSettingsView: View {
    private let blog: Blog
    @ObservedObject private var settings: BlogSettings

    init(blog: Blog) {
        self.blog = blog
        assert(blog.settings != nil, "Settings should never be nil")
        self.settings = blog.settings ?? BlogSettings(context: ContextManager.shared.mainContext)
    }

    var body: some View {
        Form {
            settingsSection
            if settings.relatedPostsEnabled {
                previewsSection
            }
        }
        .toggleStyle(SwitchToggleStyle(tint: Color(UIColor.jetpackGreen)))
        .onChange(of: settings.relatedPostsEnabled) {
            save(field: "show_related_posts", value: $0)
        }
        .onChange(of: settings.relatedPostsShowHeadline) {
            save(field: "show_related_posts_header", value: $0)
        }
        .onChange(of: settings.relatedPostsShowThumbnails) {
            save(field: "show_related_posts_thumbnail", value: $0)
        }
        .navigationTitle(Strings.title)
        .navigationBarTitleDisplayMode(.inline)
    }

    private var settingsSection: some View {
        let section = Section {
            Toggle(Strings.showRelatedPosts, isOn: $settings.relatedPostsEnabled)
            if settings.relatedPostsEnabled {
                Toggle(Strings.showHeader, isOn: $settings.relatedPostsShowHeadline)
                Toggle(Strings.showThumbnail, isOn: $settings.relatedPostsShowThumbnails)
            }
        } footer: {
            Text(Strings.optionsFooter)
        }
        if #available(iOS 15, *) {
            return section.tint(Color(UIColor.jetpackGreen))
        } else {
            return section.toggleStyle(SwitchToggleStyle(tint: Color(UIColor.jetpackGreen)))
        }
    }

    private var previewsSection: some View {
        Section {
            VStack(spacing: settings.relatedPostsShowThumbnails ? 10 : 5) {
                if settings.relatedPostsShowHeadline {
                    Text(Strings.relatedPostsHeader)
                        .font(.system(size: 11, weight: .semibold))
                        .foregroundColor(Color(UIColor.neutral))
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
                ForEach(PreviewViewModel.previews, content: makePreview)
            }
        } header: {
            Text(Strings.previewsHeader)
        }
    }

    private func makePreview(for viewModel: PreviewViewModel) -> some View {
        VStack(spacing: 5) {
            if settings.relatedPostsShowThumbnails {
                Image(viewModel.imageName)
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .frame(height: Constants.imageViewHeight)
                    .clipped()
            }
            HStack {
                VStack(alignment: .leading, spacing: 0) {
                    Text(viewModel.title)
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(Color(UIColor.neutral(.shade70)))
                    Text(viewModel.details)
                        .font(.system(size: 11).italic())
                        .foregroundColor(Color(UIColor.neutral))
                }
                Spacer()
            }
        }
    }

    private func save(field: String, value: Any) {
        WPAnalytics.trackSettingsChange("related_posts", fieldName: field, value: value)
        BlogService(coreDataStack: ContextManager.shared).updateSettings(for: blog, success: nil, failure: { _ in
            SVProgressHUD.showDismissibleError(withStatus: Strings.saveFailed)
        })
    }
}

private struct PreviewViewModel: Identifiable {
    let id = UUID()
    let title: String
    let details: String
    let imageName: String

    static let previews: [PreviewViewModel] = [
        PreviewViewModel(
            title: NSLocalizedString("relatedPostsSettings.preview1.title", value: "Big iPhone/iPad Update Now Available", comment: "Text for related post cell preview"),
            details: NSLocalizedString("relatedPostsSettings.preview1.details", value: "in \"Mobile\"", comment: "Text for related post cell preview"),
            imageName: "relatedPostsPreview1"
        ),
        PreviewViewModel(
            title: NSLocalizedString("relatedPostsSettings.preview2.title", value: "The WordPress for Android App Gets a Big Facelift", comment: "Text for related post cell preview"),
            details: NSLocalizedString("relatedPostsSettings.preview2.details", value: "in \"Apps\"", comment: "Text for related post cell preview"),
            imageName: "relatedPostsPreview2"
        ),
        PreviewViewModel(
            title: NSLocalizedString("relatedPostsSettings.preview3.title", value: "Upgrade Focus: VideoPress For Weddings", comment: "Text for related post cell preview"),
            details: NSLocalizedString("relatedPostsSettings.preview3.details", value: "in \"Upgrade\"", comment: "Text for related post cell preview"),
            imageName: "relatedPostsPreview3"
        )
    ]
}

private extension RelatedPostsSettingsView {
    enum Strings {
        static let title = NSLocalizedString("relatedPostsSettings.title", value: "Related Posts", comment: "Title for screen that allows configuration of your blog/site related posts settings.")
        static let showRelatedPosts = NSLocalizedString("relatedPostsSettings.showRelatedPosts", value: "Show Related Posts", comment: "Label for configuration switch to enable/disable related posts")
        static let showHeader = NSLocalizedString("relatedPostsSettings.showHeader", value: "Show Header", comment: "Label for configuration switch to show/hide the header for the related posts section")
        static let showThumbnail = NSLocalizedString("relatedPostsSettings.showThumbnail", value: "Show Images", comment: "Label for configuration switch to show/hide images thumbnail for the related posts")
        static let optionsFooter = NSLocalizedString("relatedPostsSettings.optionsFooter", value: "Related Posts displays relevant content from your site below your posts", comment: "Information of what related post are and how they are presented")
        static let previewsHeader = NSLocalizedString("relatedPostsSettings.previewsHeaders", value: "Preview", comment: "Section title for related posts section preview")
        static let relatedPostsHeader = NSLocalizedString("relatedPostsSettings.relatedPostsHeader", value: "Related Posts", comment: "Label for Related Post header preview")
        static let saveFailed = NSLocalizedString("relatedPostsSettings.settingsUpdateFailed", value: "Settings update failed", comment: "Message to show when setting save failed")
    }

    enum Constants {
        static let imageViewHeight: CGFloat = 96
    }
}
