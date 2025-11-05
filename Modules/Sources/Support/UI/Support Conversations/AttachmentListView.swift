import SwiftUI

struct ImageGalleryView: View {

    @Environment(\.dismiss) private var dismiss

    private let attachments: [Attachment]
    private let selectedAttachment: Attachment

    init(attachments: [Attachment], selectedAttachment: Attachment) {
        self.attachments = attachments.filter { $0.isImage }
        self.selectedAttachment = selectedAttachment
    }

    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()

            TabView {
                ForEach(attachments) { attachment in
                    SingleImageView(attachment: attachment)
                        .tag(attachment.id)
                        .foregroundStyle(.white)
                }
            }
            .tabViewStyle(.page(indexDisplayMode: .always))
            .indexViewStyle(.page(backgroundDisplayMode: .always))
        }.toolbar {
            ToolbarItem {
                Button("Done") {
                    dismiss()
                }
            }
        }
    }
}

struct SingleImageView: View {
    let attachment: Attachment

    @GestureState private var currentZoom = 1.0

    var magnification: some Gesture {
        MagnifyGesture().updating($currentZoom, body: { newValue, state, transaction in
            state = newValue.magnification
        })
    }

    var body: some View {
        AsyncImage(url: attachment.url) { image in
            image
                .resizable()
                .aspectRatio(contentMode: .fit)
                .scaleEffect(currentZoom)
                .scaledToFit()
                .gesture(magnification)
        } placeholder: {
            ProgressView("Loading Image")
        }
    }
}

struct AttachmentListView: View {
    let attachments: [Attachment]

    @State private var selectedAttachment: Attachment?

    private let columns = [
        GridItem(.adaptive(minimum: 80, maximum: 120), spacing: 8)
    ]

    private var imageAttachments: [Attachment] {
        attachments.filter { $0.contentType.hasPrefix("image/") }
    }

    var body: some View {
        LazyVGrid(columns: columns, spacing: 16) {
            ForEach(attachments, id: \.id) { attachment in
                AttachmentThumbnailView(attachment: attachment) {
                    if attachment.contentType.hasPrefix("image/") {
                        selectedAttachment = attachment
                    }
                }
            }
        }
        .padding(.top, 8)
        .fullScreenCover(item: $selectedAttachment) { attachment in
            NavigationStack {
                ImageGalleryView(
                    attachments: imageAttachments,
                    selectedAttachment: attachment
                )
            }
        }
    }
}

struct AttachmentThumbnailView: View {
    let attachment: Attachment
    let onTap: () -> Void

    var body: some View {
        Button {
            onTap()
        } label: {
            ZStack {
                if attachment.isImage {
                    AsyncImage(url: attachment.url) { image in
                        image
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                    } placeholder: {
                        Color.gray.opacity(0.2).overlay {
                            ProgressView()
                        }
                    }
                } else {
                    Color.gray.opacity(0.2)
                        .overlay {
                            VStack(spacing: 4) {
                                Image(systemName: "doc")
                                    .font(.title2)
                                    .foregroundColor(.secondary)
                                Text(attachment.filename)
                                    .font(.caption2)
                                    .foregroundColor(.secondary)
                            }
                        }
                }
            }
            .frame(width: 80, height: 80)
            .clipShape(RoundedRectangle(cornerRadius: 8))
            .overlay(
                RoundedRectangle(cornerRadius: 8)
                    .stroke(Color.gray.opacity(0.3), lineWidth: 0.5)
            )
        }
        .buttonStyle(.plain)
    }
}

typealias ImageUrl = String

extension ImageUrl: @retroactive Identifiable {
    public var id: String {
        self
    }

    var url: URL {
        URL(string: self)!
    }
}

#Preview {

    let images = [
        "https://picsum.photos/seed/1/800/600",
        "https://picsum.photos/seed/2/800/600",
        "https://picsum.photos/seed/3/800/600",
        "https://picsum.photos/seed/4/800/600",
        "https://picsum.photos/seed/5/800/600",
    ].map { ImageUrl($0) }.map { Attachment(
        id: .random(in: 0...UInt64.max),
        filename: $0.url.lastPathComponent,
        contentType: "image/jpeg",
        fileSize: 123456,
        url: $0.url
    )  }

    AttachmentListView(attachments: images)
}
