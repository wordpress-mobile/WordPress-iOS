import Foundation
import SwiftSoup

class GutenbergGalleryUploadProcessor: GutenbergProcessor {

    let mediaUploadID: Int32
    let remoteURLString: String
    let serverMediaID: Int
    let mediaLink: String

    private var linkToURL: String?

    static let imgClassIDPrefixAttribute = "wp-image-"

    init(mediaUploadID: Int32, serverMediaID: Int, remoteURLString: String, mediaLink: String) {
        self.mediaUploadID = mediaUploadID
        self.serverMediaID = serverMediaID
        self.remoteURLString = remoteURLString
        self.mediaLink = mediaLink
    }

    private struct ImageKeys {
        static let name = "img"
        static let classAttributes = "class"
        static let classIDPrefix = "wp-image-"
        static let dataID = "data-id"
        static let dataFullURL = "data-full-url"
        static let dataLink = "data-link"
    }

    func processImgPostMediaUpload(_ element: Element) {
        guard let imgTags = try? element.select(ImageKeys.name) else {
            return
        }
        imgTags.forEach {imgTag in
            guard let imgClass = try? imgTag.attr(ImageKeys.classAttributes) else {
                return
            }

            let classAttributes = imgClass.components(separatedBy: " ")

            guard let imageIDAttribute = classAttributes.filter({ (value) -> Bool in
                value.hasPrefix(GutenbergImgUploadProcessor.imgClassIDPrefixAttribute)
            }).first else {
                return
            }

            let imageIDString = String(imageIDAttribute.dropFirst(ImageKeys.classIDPrefix.count))
            let imgUploadID = Int32(imageIDString)

            guard imgUploadID == self.mediaUploadID else {
                return
            }

            let newImgClassAttributes = imgClass.replacingOccurrences(of: imageIDAttribute, with: ImageKeys.classIDPrefix + String(self.serverMediaID))

            _ = try? imgTag.attr("src", self.remoteURLString)
            _ = try? imgTag.attr("class", newImgClassAttributes)
            _ = try? imgTag.attr(ImageKeys.dataID, String(self.serverMediaID))
            _ = try? imgTag.attr(ImageKeys.dataFullURL, self.remoteURLString)

            if let _ = try? imgTag.attr(ImageKeys.dataLink) {
                _ = try? imgTag.attr(ImageKeys.dataLink, self.mediaLink)
            }
        }
    }

    private struct LinkKeys {
        static let name = "a"
    }

    func processLinkPostMediaUpload(_ block: GutenbergParsedBlock) {
        guard let aTags = try? block.elements.select(LinkKeys.name) else {
            return
        }
        aTags.forEach { aTag in
            guard let linkOriginalContent = try? aTag.html() else {
                return
            }

            processImgPostMediaUpload(aTag)
            let linkUpdatedContent = try? aTag.html()

            guard linkUpdatedContent != linkOriginalContent else {
                return
            }

            if let linkToURL = self.linkToURL {
                _ = try? aTag.attr("href", linkToURL)
            } else {
                _ = try? aTag.attr("href", self.remoteURLString)
            }
        }
    }

    private struct GalleryBlockKeys {
        static let name = "wp:gallery"
        static let ids = "ids"
        static let linkTo = "linkTo"
    }

    private func convertToIntArray(_ idsAny: [Any]) -> [Int32] {
        var ids = [Int32]()
        for id in idsAny {
            if let idInt = id as? Int32 {
                ids.append(idInt)
            } else if let idString = id as? String, let idInt = Int32(idString) {
                ids.append(idInt)
            }
        }
        return ids
    }

    func processGalleryBlocks(_ blocks: [GutenbergParsedBlock]) {
        let galleryBlocks = blocks.filter { $0.name == GalleryBlockKeys.name }
        galleryBlocks.forEach { block in
            guard let idsAny = block.attributes[GalleryBlockKeys.ids] as? [Any] else {
                    return
            }
            var ids = self.convertToIntArray(idsAny)
            guard ids.contains(self.mediaUploadID) else {
                return
            }
            if let index = ids.firstIndex(of: self.mediaUploadID ) {
                ids[index] = Int32(self.serverMediaID)
            }
            block.attributes[GalleryBlockKeys.ids] = ids

            if let linkTo = block.attributes[GalleryBlockKeys.linkTo] as? String, linkTo != "none" {
                if linkTo == "file" {
                    self.linkToURL = self.remoteURLString
                } else if linkTo == "post" {
                    self.linkToURL = self.mediaLink
                }
                processLinkPostMediaUpload(block)
            } else {
                block.elements.forEach { processImgPostMediaUpload($0) }
            }
        }
    }

    func process(_ blocks: [GutenbergParsedBlock]) {
        processGalleryBlocks(blocks)
    }
}
