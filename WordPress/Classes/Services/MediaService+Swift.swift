
extension MediaService {

    @objc(updateMedia:withRemoteMedia:)
    func update(media: Media, with remoteMedia: RemoteMedia) {
        if media.mediaID != remoteMedia.mediaID {
            media.mediaID =  remoteMedia.mediaID
        }
        if media.remoteURL != remoteMedia.url?.absoluteString {
            media.remoteURL = remoteMedia.url?.absoluteString
        }
        if remoteMedia.date != nil && remoteMedia.date != media.creationDate {
            media.creationDate = remoteMedia.date
        }
        if media.filename != remoteMedia.file {
            media.filename = remoteMedia.file
        }
        if let mimeType = remoteMedia.mimeType, !mimeType.isEmpty {
            media.setMediaTypeForMimeType(mimeType)
        } else if let fileExtension = remoteMedia.extension, !fileExtension.isEmpty {
            media.setMediaTypeForExtension(fileExtension)
        }
        if media.title != remoteMedia.title {
            media.title = remoteMedia.title
        }
        if media.caption != remoteMedia.caption {
            media.caption = remoteMedia.caption
        }
        if media.desc != remoteMedia.descriptionText {
            media.desc = remoteMedia.descriptionText
        }
        if media.alt != remoteMedia.alt {
            media.alt = remoteMedia.alt
        }
        if media.height != remoteMedia.height {
            media.height = remoteMedia.height
        }
        if media.width != remoteMedia.width {
            media.width = remoteMedia.width
        }
        if media.shortcode != remoteMedia.shortcode {
            media.shortcode = remoteMedia.shortcode
        }
        if media.videopressGUID != remoteMedia.videopressGUID {
            media.videopressGUID = remoteMedia.videopressGUID
        }
        if media.length != remoteMedia.length {
            media.length = remoteMedia.length
        }
        if media.remoteThumbnailURL != remoteMedia.remoteThumbnailURL {
            media.remoteThumbnailURL = remoteMedia.remoteThumbnailURL
        }
        if media.postID != remoteMedia.postID {
            media.postID = remoteMedia.postID
        }
        if media.remoteStatus != .sync {
            media.remoteStatus = .sync
        }
        if media.error != nil {
            media.error = nil
        }

    }

}
