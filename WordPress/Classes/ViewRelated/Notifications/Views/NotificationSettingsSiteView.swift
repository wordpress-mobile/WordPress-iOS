import Foundation
import SwiftUI
import WordPressUI

struct NotificationSettingsSiteView: View {
    let viewModel: NotificationSettingsSiteViewModel

    var body: some View {
        HStack(alignment: .center, spacing: 16) {
            SiteIconView(viewModel: viewModel.icon)
                .frame(width: 32, height: 32)

            VStack(alignment: .leading) {
                Text(viewModel.title)
                    .font(.body)
                    .lineLimit(1)

                Text(viewModel.details)
                    .font(.footnote)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
            }
        }
    }
}

struct NotificationSettingsSiteViewModel {
    let title: String
    let details: String
    let icon: SiteIconViewModel

    init(blog: Blog) {
        self.title = blog.title ?? "–"
        self.details = blog.displayURL as String? ?? ""
        self.icon = SiteIconViewModel(blog: blog)
    }

    init(topic: ReaderSiteTopic) {
        self.title = topic.title
        self.details = URL(string: topic.siteURL)?.host(percentEncoded: false) ?? ""
        self.icon = SiteIconViewModel(readerSiteTopic: topic)
    }
}
