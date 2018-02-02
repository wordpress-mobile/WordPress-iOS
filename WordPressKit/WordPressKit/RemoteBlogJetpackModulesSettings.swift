import Foundation


/// This struct encapsulates the *remote* Jetpack modules settings available for a Blog entity
///
public struct RemoteBlogJetpackModulesSettings {

    /// Indicates whether the Jetpack site lazy loads images.
    ///
    public let lazyLoadImages: Bool

    /// Indicates whether the Jetpack site serves images from our server.
    ///
    public let serveImagesFromOurServers: Bool

    public init(lazyLoadImages: Bool, serveImagesFromOurServers: Bool) {
        self.lazyLoadImages = lazyLoadImages
        self.serveImagesFromOurServers = serveImagesFromOurServers
    }

}
