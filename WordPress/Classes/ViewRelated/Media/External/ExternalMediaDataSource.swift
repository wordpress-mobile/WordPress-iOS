import Foundation

/// A media asset protocol used to export media from external sources
///
protocol ExternalMediaAsset: AnyObject, ExportableAsset {
    var id: String { get }
    var thumbnailURL: URL { get }
    var largeURL: URL { get }
    var name: String { get }
    var caption: String { get }
}

protocol ExternalMediaDataSource: AnyObject {
    var assets: [ExternalMediaAsset] { get }
    var onUpdatedAssets: (() -> Void)? { get set }
    var onStartLoading: (() -> Void)? { get set }
    var onStopLoading: (() -> Void)? { get set }
    func search(for searchTerm: String)
    func loadMore()
}
