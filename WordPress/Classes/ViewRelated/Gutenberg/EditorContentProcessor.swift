import Aztec
import Foundation

struct EditorUploadedMedia {
    let mediaID: Int
    let remoteURL: String
    let mediaType: MediaType

    let link: String
    let uploadID: String
    let gutenbergUploadID: Int32
    let imageURL: String
    let videopressGUID: String?
    let width: Int?
    let height: Int?

    init?(media: Media) {
        guard let mediaID = media.mediaID?.intValue, mediaID > 0,
              let remoteURL = media.remoteURL else {
            return nil
        }
        self.mediaID = mediaID
        self.remoteURL = remoteURL
        self.mediaType = media.mediaType

        self.link = media.link
        self.uploadID = media.uploadID
        self.gutenbergUploadID = media.gutenbergUploadID
        self.imageURL = (media.remoteLargeURL ?? media.remoteMediumURL ?? remoteURL)
        self.videopressGUID = media.videopressGUID
        self.width = media.width?.intValue
        self.height = media.height?.intValue
    }
}

enum EditorContentProcessor {
    static func updateMediaReferences(for media: [EditorUploadedMedia], in content: String) async -> String {
        var content = content
        for item in media {
            content = updateReferences(for: item, in: content)
        }
        return content
    }

    private static func updateReferences(for media: EditorUploadedMedia, in content: String) -> String {
        // Gutenberg processors need to run first because they are more specific
        // and target only content inside specific blocks. Aztec processors are
        // next because they are more generic and only worried about HTML tags.
        var content = content
        let processors = makeGutenbergProcessors(for: media) + makeAztecProcessors(for: media)
        for processor in processors {
            content = processor.process(content)
        }
        return content
    }

    private static func makeGutenbergProcessors(for media: EditorUploadedMedia) -> [Processor] {
        var processors: [Processor] = []
        // File block can upload any kind of media.
        processors.append(GutenbergFileUploadProcessor(mediaUploadID: media.gutenbergUploadID, serverMediaID: media.mediaID, remoteURLString: media.remoteURL))
        switch media.mediaType {
        case .image:
            processors.append(GutenbergImgUploadProcessor(mediaUploadID: media.gutenbergUploadID, serverMediaID: media.mediaID, remoteURLString: media.imageURL))
            processors.append(GutenbergGalleryUploadProcessor(mediaUploadID: media.gutenbergUploadID, serverMediaID: media.mediaID, remoteURLString: media.imageURL, mediaLink: media.link))
            processors.append(GutenbergCoverUploadProcessor(mediaUploadID: media.gutenbergUploadID, serverMediaID: media.mediaID, remoteURLString: media.remoteURL))
        case .video:
            processors.append(GutenbergVideoUploadProcessor(mediaUploadID: media.gutenbergUploadID, serverMediaID: media.mediaID, remoteURLString: media.remoteURL))
            processors.append(GutenbergCoverUploadProcessor(mediaUploadID: media.gutenbergUploadID, serverMediaID: media.mediaID, remoteURLString: media.remoteURL))
            if let videoPressGUID = media.videopressGUID {
                processors.append(GutenbergVideoPressUploadProcessor(mediaUploadID: media.gutenbergUploadID, serverMediaID: media.mediaID, videoPressGUID: videoPressGUID))
            }
        case .audio:
            processors.append(GutenbergAudioUploadProcessor(mediaUploadID: media.gutenbergUploadID, serverMediaID: media.mediaID, remoteURLString: media.remoteURL))
        default:
            break
        }
        return processors
    }

    private static func makeAztecProcessors(for media: EditorUploadedMedia) -> [Processor] {
        var processors: [Processor] = []
        switch media.mediaType {
        case .image:
            processors.append(ImgUploadProcessor(mediaUploadID: media.uploadID, remoteURLString: media.remoteURL, width: media.width, height: media.height))
        case .video:
            processors.append(VideoUploadProcessor(mediaUploadID: media.uploadID, remoteURLString: media.remoteURL, videoPressID: media.videopressGUID))
        default:
            break
        }
        if let remoteURL = URL(string: media.remoteURL) {
            processors.append(DocumentUploadProcessor(mediaUploadID: media.uploadID, remoteURLString: media.remoteURL, title: remoteURL.lastPathComponent))
        }
        return processors
    }
}
