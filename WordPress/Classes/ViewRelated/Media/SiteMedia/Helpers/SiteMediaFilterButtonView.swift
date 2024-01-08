import UIKit

struct SiteMediaFilter {
    let mediaType: MediaType?
    let title: String
    let imageName: String?

    var image: UIImage? { imageName.flatMap { UIImage(systemName: $0) } }

    static let allFilters: [SiteMediaFilter] = [
        SiteMediaFilter(mediaType: nil, title: Strings.filterAll, imageName: nil),
        SiteMediaFilter(mediaType: .image, title: Strings.filterImages, imageName: "photo"),
        SiteMediaFilter(mediaType: .video, title: Strings.filterVideos, imageName: "video"),
        SiteMediaFilter(mediaType: .document, title: Strings.filterDocuments, imageName: "folder"),
        SiteMediaFilter(mediaType: .audio, title: Strings.filterAudio, imageName: "waveform")
    ]
}

private enum Strings {
    static let filterAll = NSLocalizedString("mediaLibrary.filterAll", value: "All", comment: "The name of the media filter")
    static let filterImages = NSLocalizedString("mediaLibrary.filterImages", value: "Images", comment: "The name of the media filter")
    static let filterVideos = NSLocalizedString("mediaLibrary.filterVideos", value: "Videos", comment: "The name of the media filter")
    static let filterDocuments = NSLocalizedString("mediaLibrary.filterDocuments", value: "Documents", comment: "The name of the media filter")
    static let filterAudio = NSLocalizedString("mediaLibrary.filterAudio", value: "Audio", comment: "The name of the media filter")
}
