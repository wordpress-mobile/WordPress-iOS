import Foundation

/// A media asset protocol used to export media from external sources
///
protocol ExternalMediaAsset {
    var id: String { get }
    var thumbnailURL: URL { get }
    var largeURL: URL { get }
    var name: String { get }
    var caption: String { get }
}
