
import Foundation
import WPMediaPicker

/// This class is intended to be used with WPMediaPicker delegate `mediaPickerController(_:previewViewControllerFor:selectedIndex:)`
/// making this implementation reusable with all the instances of the media picker.
///
class MediaPreviewHelper: NSObject {


    /// Return a controller to show the given assets.
    ///
    /// - Parameters:
    ///   - assets: The media assets to be displayed in the controller.
    ///   - selected: The selected index to be displayed by default.
    /// - Returns: The controller to be displayed or nil if the asset is not an image.
    func previewViewController(for assets: [WPMediaAsset], selectedIndex selected: Int) -> UIViewController? {
        guard assets.count > 0, selected < assets.endIndex else {
            return nil
        }

        if assets.count > 1 {
            return carouselController(with: assets, selectedIndex: selected)
        }

        let selectedAsset = assets[selected]
        return self.viewController(for: selectedAsset)
    }

    private func carouselController(with assets: [WPMediaAsset], selectedIndex selected: Int) -> UIViewController {
        let carouselViewController = WPCarouselAssetsViewController(assets: assets)
        carouselViewController.setPreviewingAssetAt(selected, animated: false)
        carouselViewController.carouselDelegate = self
        return carouselViewController
    }

    fileprivate func imageViewController(with mediaAsset: Media) -> UIViewController {
        let imageController = WPImageViewController(media: mediaAsset)
        imageController.shouldDismissWithGestures = false
        return imageController
    }

    private func viewController(for asset: WPMediaAsset) -> UIViewController? {
        guard asset.assetType() == .image else {
            return nil
        }

        if let mediaAsset = asset as? Media {
            return imageViewController(with: mediaAsset)
        } else if let phasset = asset as? PHAsset {
            let imageController =  WPImageViewController(asset: phasset)
            imageController.shouldDismissWithGestures = false
            return imageController
        } else if let mediaAsset = asset as? MediaExternalAsset {
            let imageController =  WPImageViewController(externalMediaURL: mediaAsset.URL)
            imageController.shouldDismissWithGestures = false
            return imageController
        }

        return nil
    }
}

extension MediaPreviewHelper: WPCarouselAssetsViewControllerDelegate {
    func carouselController(_ controller: WPCarouselAssetsViewController, viewControllerFor asset: WPMediaAsset) -> UIViewController? {
        return viewController(for: asset)
    }

    func carouselController(_ controller: WPCarouselAssetsViewController, assetFor viewController: UIViewController) -> WPMediaAsset {
        guard
            let imageViewController = viewController as? WPImageViewController,
            let asset = imageViewController.mediaAsset else {

                fatalError()
        }
        return asset
    }
}
