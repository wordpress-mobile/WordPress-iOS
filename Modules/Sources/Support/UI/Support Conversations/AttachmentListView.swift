import SwiftUI
import AsyncImageKit
import PDFKit
import AVKit

struct SingleImageView: View {

    let url: URL

    @GestureState private var currentZoom = 1.0

    var magnification: some Gesture {
        MagnifyGesture().updating($currentZoom, body: { newValue, state, transaction in
            state = newValue.magnification
        })
    }

    var body: some View {
        CachedAsyncImage(url: url) { image in
            image
                .resizable()
                .aspectRatio(contentMode: .fit)
                .scaleEffect(currentZoom)
                .scaledToFit()
                .gesture(magnification)
        } placeholder: {
            ProgressView("Loading Image")
        }
        .navigationTitle(url.lastPathComponent)
    }
}

struct SingleVideoView: View {
    private let player: AVPlayer

    init(url: URL) {
        self.player = AVPlayer(url: url)
    }

    var body: some View {
        VideoPlayer(player: player)
            .ignoresSafeArea()
            .onAppear {
                self.player.play()
            }
    }
}

struct SinglePDFView: UIViewRepresentable {
    let url: URL // Or Data for in-memory PDFs

    func makeUIView(context: Context) -> PDFView {
        let pdfView = PDFView()
        if let document = PDFDocument(url: url) {
            pdfView.document = document
        }
        return pdfView
    }

    func updateUIView(_ uiView: PDFView, context: Context) {
        // Update the view if the URL or other properties change
        if let document = PDFDocument(url: url) {
            uiView.document = document
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
        attachments.filter { $0.isImage || $0.isVideo }
    }

    private var otherAttachments: [Attachment] {
        attachments.filter { !$0.isImage && !$0.isVideo }
    }

    var body: some View {
        VStack(alignment: .leading) {
            LazyVGrid(columns: columns, spacing: 16) {
                ForEach(imageAttachments) { attachment in
                    AttachmentThumbnailView(attachment: attachment)
                }
            }

            ForEach(otherAttachments) { attachment in
                AttachmentRowView(attachment: attachment)
            }
        }
    }
}

struct AttachmentThumbnailView: View {
    let attachment: Attachment

    var body: some View {
        NavigationLink {
            if attachment.isImage {
                SingleImageView(url: attachment.url)
            }

            if attachment.isVideo {
                SingleVideoView(url: attachment.url)
            }
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
                }

                if attachment.isVideo {
                    CachedAsyncVideoPreview(url: attachment.url) { image in
                        image
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                            .overlay {
                                Image(systemName: "play.circle")
                                    .foregroundStyle(Color.white)
                            }

                    } placeholder: {
                        Color.gray.opacity(0.2).overlay {
                            ProgressView()
                        }
                    }
                }
            }
            .frame(width: 80, height: 80)
            .clipShape(RoundedRectangle(cornerRadius: 8))
        }
        .buttonStyle(.plain)
    }
}

struct AttachmentRowView: View {

    let attachment: Attachment

    var body: some View {
        NavigationLink {
            if attachment.isPdf {
                SinglePDFView(url: attachment.url)
                    .navigationTitle(attachment.filename)
            }
        } label: {
            HStack(alignment: .firstTextBaseline) {
                Image(systemName: attachment.icon)
                    .foregroundColor(.secondary)
                    .font(.body)
                    .frame(width: 40, height: 40)
                Text(attachment.filename)
                    .font(.body)
                    .foregroundColor(.secondary)
                    .lineLimit(1)
                Spacer()
            }
            .background(Color(UIColor.secondarySystemBackground))
            .clipShape(RoundedRectangle(cornerRadius: 8))
            .padding(.bottom, 4)
        }
    }
}

typealias ImageUrl = String

extension ImageUrl: @retroactive Identifiable {
    public var id: String {
        self
    }

    var filename: String {
        self.url.lastPathComponent
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
        filename: $0.filename,
        contentType: "image/jpeg",
        fileSize: 123456,
        url: $0.url
    )  }

    let documents = [
        "https://www.rd.usda.gov/sites/default/files/pdf-sample_0.pdf"
    ].map { ImageUrl($0) }.map { Attachment(
        id: .random(in: 0...UInt64.max),
        filename: $0.filename,
        contentType: "application/pdf",
        fileSize: 45678,
        url: $0.url
    )}

    let videos = [
        "https://a8c.zendesk.com/attachments/token/Le9xjU6B0nfYjtActesrzRrcm/?name=file_example_MP4_1920_18MG.mp4"
    ].map { ImageUrl($0) }.map { Attachment(
        id: .random(in: 0...UInt64.max),
        filename: "file_example_MP4_1920_18MG.mp4",
        contentType: "video/mp4",
        fileSize: 99842342,
        url: $0.url
    )}

    NavigationStack {
        AttachmentListView(attachments: images + documents + videos)
    }
}
