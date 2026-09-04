import SwiftUI

/// The pinned author row: avatar, name, resolved post title, and relative
/// date. Tapping it reveals the author info sheet (full date plus the contact
/// details edit context carries).
struct CommentAuthorHeader: View {
    let header: CommentDetailViewModel.Header
    let titleState: PostTitleResolver.TitleState
    /// Present once the authoritative fetch lands; supplies the website, email,
    /// and IP the info sheet shows.
    let detail: CommentDetail?

    @State private var isInfoPresented = false

    var body: some View {
        Button {
            isInfoPresented = true
        } label: {
            content
        }
        .buttonStyle(.plain)
        .sheet(isPresented: $isInfoPresented) {
            CommentAuthorInfoSheet(header: header, detail: detail)
        }
    }

    private var content: some View {
        HStack(alignment: .top, spacing: 12) {
            CommentAvatarView(url: header.avatarURL)
            VStack(alignment: .leading, spacing: 2) {
                Text(header.authorName)
                    .font(.subheadline.weight(.semibold))
                postLine
                if let date = header.date {
                    Text(date, format: .relative(presentation: .named))
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
            Spacer(minLength: 0)
            Image(systemName: "info.circle")
                .foregroundStyle(.secondary)
        }
        .contentShape(Rectangle())
    }

    @ViewBuilder
    private var postLine: some View {
        switch titleState {
        case .resolved(let title):
            postLineText(title)
        case .loading:
            postLineText("Sample Post Title")
                .redacted(reason: .placeholder)
        case .unavailable:
            EmptyView()
        }
    }

    private func postLineText(_ title: String) -> some View {
        Text(String(format: Strings.authorHeaderOnPost, title))
            .font(.footnote)
            .foregroundStyle(.secondary)
            .lineLimit(1)
    }
}

/// Author details presented as a medium sheet. Website, email, and IP appear
/// only when the fetched detail carries them (email and IP require edit
/// context).
private struct CommentAuthorInfoSheet: View {
    let header: CommentDetailViewModel.Header
    let detail: CommentDetail?

    var body: some View {
        NavigationStack {
            List {
                if let date = header.date {
                    LabeledContent(Strings.infoDateLabel, value: date.formatted(.dateTime))
                }
                if let url = detail?.authorURL {
                    Link(destination: url) {
                        LabeledContent(Strings.infoWebsiteLabel, value: url.absoluteString)
                    }
                }
                if let email = detail?.authorEmail {
                    LabeledContent(Strings.infoEmailLabel, value: email)
                }
                if let ip = detail?.authorIP {
                    LabeledContent(Strings.infoIPLabel, value: ip)
                }
            }
            .navigationTitle(header.authorName)
            .navigationBarTitleDisplayMode(.inline)
        }
        .presentationDetents([.medium])
    }
}
