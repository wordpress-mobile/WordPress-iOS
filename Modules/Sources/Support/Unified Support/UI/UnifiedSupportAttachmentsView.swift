import SwiftUI
import AsyncImageKit

/// The files attached to a message, and the pages the AI Assistant used to answer.
struct UnifiedSupportAttachmentsView: View {

    let attachments: [UnifiedSupportAttachment]

    private var links: [UnifiedSupportAttachment] {
        attachments.filter { $0.kind == .link }
    }

    private var files: [UnifiedSupportAttachment] {
        attachments.filter { $0.kind != .link }
    }

    private let columns = [GridItem(.adaptive(minimum: 110, maximum: 160), spacing: 8)]

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            ForEach(links) { link in
                UnifiedSupportAttachmentLink(attachment: link)
            }

            if !files.isEmpty {
                LazyVGrid(columns: columns, alignment: .leading, spacing: 8) {
                    ForEach(files) { file in
                        UnifiedSupportAttachmentTile(attachment: file)
                    }
                }
            }
        }
    }
}

private struct UnifiedSupportAttachmentLink: View {

    let attachment: UnifiedSupportAttachment

    @Environment(\.openURL)
    private var openURL

    var body: some View {
        Button {
            openURL(attachment.url)
        } label: {
            HStack(alignment: .firstTextBaseline, spacing: 6) {
                Image(systemName: "arrow.up.forward.square")
                Text(attachment.filename)
                    .underline()
                    .multilineTextAlignment(.leading)
            }
            .font(.subheadline)
        }
        .buttonStyle(.plain)
        .foregroundStyle(Color.accentColor)
        .accessibilityLabel(
            String.localizedStringWithFormat(UnifiedSupportLocalization.openLink, attachment.filename)
        )
    }
}

private struct UnifiedSupportAttachmentTile: View {

    let attachment: UnifiedSupportAttachment

    @EnvironmentObject
    private var context: UnifiedSupportContext

    private let size: CGFloat = 120

    var body: some View {
        switch attachment.kind {
        case .image:
            NavigationLink {
                // The media host is passed in: a pushed screen doesn't inherit the environment here, since
                // navigation is owned by UIKit.
                UnifiedSupportImageViewer(attachment: attachment, host: context.mediaHost)
            } label: {
                imageThumbnail
            }
            .buttonStyle(.plain)
        case .video:
            NavigationLink {
                SingleVideoView(url: attachment.url, host: context.mediaHost)
                    .navigationTitle(attachment.filename)
            } label: {
                videoThumbnail
            }
            .buttonStyle(.plain)
        case .link, .other:
            // Opening other files needs an authenticated download, which isn't supported yet.
            fileThumbnail
        }
    }

    private var imageThumbnail: some View {
        CachedAsyncImage(url: attachment.url, host: context.mediaHost, mutability: .immutable) { image in
            image
                .resizable()
                .aspectRatio(contentMode: .fill)
        } placeholder: {
            placeholder { ProgressView() }
        }
        .modifier(UnifiedSupportAttachmentTileStyle(size: size))
        .accessibilityLabel(attachment.filename)
    }

    private var videoThumbnail: some View {
        CachedAsyncImage(videoUrl: attachment.url, host: context.mediaHost, mutability: .immutable) { image in
            image
                .resizable()
                .aspectRatio(contentMode: .fill)
                .overlay {
                    Image(systemName: "play.circle.fill")
                        .font(.system(size: 36))
                        .foregroundStyle(.white, .black.opacity(0.4))
                }
        } placeholder: {
            placeholder { ProgressView() }
        }
        .modifier(UnifiedSupportAttachmentTileStyle(size: size))
        .accessibilityLabel(attachment.filename)
    }

    private var fileThumbnail: some View {
        placeholder {
            VStack(spacing: 4) {
                Image(systemName: "doc")
                    .font(.title2)
                Text(attachment.filename)
                    .font(.caption2)
                    .lineLimit(2)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 4)
            }
            .foregroundStyle(.secondary)
        }
        .modifier(UnifiedSupportAttachmentTileStyle(size: size))
    }

    private func placeholder<Content: View>(@ViewBuilder content: () -> Content) -> some View {
        Color(.systemGray6).overlay(content())
    }
}

private struct UnifiedSupportAttachmentTileStyle: ViewModifier {

    let size: CGFloat

    func body(content: Content) -> some View {
        content
            .frame(width: size, height: size)
            .clipShape(RoundedRectangle(cornerRadius: 8))
    }
}

/// Shows an image attachment full screen, authenticating the request so private files load.
struct UnifiedSupportImageViewer: View {

    let attachment: UnifiedSupportAttachment
    let host: any MediaHostProtocol

    @GestureState private var zoom = 1.0

    var body: some View {
        CachedAsyncImage(url: attachment.url, host: host, mutability: .immutable) { image in
            image
                .resizable()
                .aspectRatio(contentMode: .fit)
                .scaleEffect(zoom)
                .gesture(
                    MagnifyGesture()
                        .updating($zoom) { value, state, _ in
                            state = value.magnification
                        }
                )
        } placeholder: {
            ProgressView(UnifiedSupportLocalization.loadingAttachment)
        }
        .navigationTitle(attachment.filename)
        .navigationBarTitleDisplayMode(.inline)
    }
}
