import AlamofireImage
import AutomatticTracks
import Foundation
import Gridicons

/// UIImageView Helper Methods that allow us to download a SiteIcon, given a website's "Icon Path"
///
extension UIImageView {

    /// Default Settings
    ///
    struct SiteIconDefaults {
        /// Default SiteIcon's Image Size, in points.
        ///
        static let imageSize = CGSize(width: 40, height: 40)
    }

    /// Downloads the SiteIcon Image, hosted at the specified path. This method will attempt to optimize the URL, so that
    /// the download Image Size matches `imageSize`.
    ///
    /// TODO: This is a convenience method. Nuke me once we're all swifted.
    ///
    /// - Parameter path: SiteIcon's url (string encoded) to be downloaded.
    ///
    @objc
    func downloadSiteIcon(at path: String) {
        downloadSiteIcon(at: path, placeholderImage: .siteIconPlaceholder)
    }

    /// Downloads the SiteIcon Image, hosted at the specified path. This method will attempt to optimize the URL, so that
    /// the download Image Size matches `imageSize`.
    ///
    /// - Parameters:
    ///     - path: SiteIcon's url (string encoded) to be downloaded.
    ///     - imageSize: Request site icon in the specified image size.
    ///     - placeholderImage: Yes. It's the "place holder image", Sherlock.
    ///
    @objc
    func downloadSiteIcon(
        at path: String,
        imageSize: CGSize = SiteIconDefaults.imageSize,
        placeholderImage: UIImage?
    ) {
        guard let siteIconURL = SiteIconViewModel.optimizedURL(for: path, imageSize: imageSize) else {
            image = placeholderImage
            return
        }

        logURLOptimization(from: path, to: siteIconURL)

        let request = URLRequest(url: siteIconURL)
        downloadSiteIcon(with: request, imageSize: imageSize, placeholderImage: placeholderImage)
    }

    /// Downloads a SiteIcon image, using a specified request.
    ///
    /// - Parameters:
    ///     - request: The request for the SiteIcon.
    ///     - imageSize: Request site icon in the specified image size.
    ///     - placeholderImage: Yes. It's the "place holder image".
    ///
    private func downloadSiteIcon(
        with request: URLRequest,
        imageSize expectedSize: CGSize = SiteIconDefaults.imageSize,
        placeholderImage: UIImage?
    ) {
        af.setImage(withURLRequest: request, placeholderImage: placeholderImage, completion: { [weak self] dataResponse in
            switch dataResponse.result {
            case .success(let image):
                guard let self = self else {
                    return
                }

                // In `MediaRequesAuthenticator.authenticatedRequestForPrivateAtomicSiteThroughPhoton` we're
                // having to replace photon URLs for Atomic Private Sites, with a call to the Atomic Media Proxy
                // endpoint.  The downside of calling that endpoint is that it doesn't always return images of
                // the requested size.
                //
                // The following lines of code ensure that we resize the image to the default Site Icon size, to
                // ensure there is no UI breakage due to having larger images set here.
                //
                if image.size != expectedSize {
                    self.image = image.resized(to: expectedSize, format: .scaleAspectFill)
                } else {
                    self.image = image
                }

                self.layer.borderColor = UIColor.clear.cgColor
            case .failure(let error):
                if case .requestCancelled = error {
                    // Do not log intentionally cancelled requests as errors.
                } else {
                    DDLogError("\(error.localizedDescription)")
                }
            }
        })
    }
}

// MARK: - Logging Support

/// This is just a temporary extension to try and narrow down the caused behind this issue: https://sentry.io/share/issue/3da4662c65224346bb3a731c131df13d/
///
private extension UIImageView {

    private func logURLOptimization(from original: String, to optimized: URL) {
        DDLogInfo("URL optimized from \(original) to \(optimized.absoluteString)")
    }

    private func logURLOptimization(from original: String, to optimized: URL, for blog: Blog) {
        let blogInfo: String
        if blog.isAccessibleThroughWPCom() {
            blogInfo = "dot-com-accessible: \(blog.url ?? "unknown"), id: \(blog.dotComID ?? 0)"
        } else {
            blogInfo = "self-hosted with url: \(blog.url ?? "unknown")"
        }

        DDLogInfo("URL optimized from \(original) to \(optimized.absoluteString) for blog \(blogInfo)")
    }
}
