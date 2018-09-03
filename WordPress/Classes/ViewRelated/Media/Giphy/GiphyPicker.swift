import WPMediaPicker
import MobileCoreServices

protocol GiphyPickerDelegate: AnyObject {
    func giphyPicker(_ picker: GiphyPicker, didFinishPicking assets: [GiphyMedia])
}

/// Presents the Giphy main interface
final class GiphyPicker: NSObject {
    private lazy var dataSource: GiphyDataSource = {
        return GiphyDataSource(service: giphyService)
    }()

    private lazy var giphyService: GiphyService = {
        return GiphyService()
    }()

    /// Helps choosing the correct view controller for previewing a media asset
    ///
    private let mediaPreviewHelper = MediaPreviewHelper()

    weak var delegate: GiphyPickerDelegate?
    private var blog: Blog?
    private var observerToken: NSObjectProtocol?

    private let searchHint = NoResultsViewController.controller()

    private var pickerOptions: WPMediaPickerOptions = {
        let options = WPMediaPickerOptions()
        options.showMostRecentFirst = true
        options.filter = [.all]
        options.allowCaptureOfMedia = false
        options.showSearchBar = true
        options.badgedUTTypes = [String(kUTTypeGIF)]
        return options
    }()

    private lazy var picker: WPNavigationMediaPickerViewController = {
        let picker = WPNavigationMediaPickerViewController(options: pickerOptions)
        picker.delegate = self
        picker.startOnGroupSelector = false
        picker.showGroupSelector = false
        picker.dataSource = dataSource
        picker.cancelButtonTitle = .closePicker
        return picker
    }()

    func presentPicker(origin: UIViewController, blog: Blog) {
        NoResultsGiphyConfiguration.configureAsIntro(searchHint)
        self.blog = blog

        origin.present(picker, animated: true) {
            self.picker.mediaPicker.searchBar?.becomeFirstResponder()
        }

        observeDataSource()
    }

    private func observeDataSource() {
        observerToken = dataSource.registerChangeObserverBlock { [weak self] (_, _, _, _, assets) in
            self?.updateHintView()
        }
        dataSource.onStartLoading = { [weak self] in
            NoResultsGiphyConfiguration.configureAsLoading(self!.searchHint)
        }
        dataSource.onStopLoading = { [weak self] in
            self?.updateHintView()
        }
    }

    private func shouldShowNoResults() -> Bool {
        return dataSource.searchQuery.count > 0 && dataSource.numberOfAssets() == 0
    }

    private func updateHintView() {
        searchHint.removeFromView()
        if shouldShowNoResults() {
            NoResultsGiphyConfiguration.configure(searchHint, asNoSearchResultsFor: dataSource.searchQuery)
        } else {
            NoResultsGiphyConfiguration.configureAsIntro(searchHint)
        }
    }

    deinit {
        if let token = observerToken {
            dataSource.unregisterChangeObserver(token)
        }
    }
}

extension GiphyPicker: WPMediaPickerViewControllerDelegate {
    func mediaPickerController(_ picker: WPMediaPickerViewController, didFinishPicking assets: [WPMediaAsset]) {
        guard let assets = assets as? [GiphyMedia] else {
            assertionFailure("assets should be of type `[GiphyMedia]`")
            return
        }
        delegate?.giphyPicker(self, didFinishPicking: assets)
        picker.dismiss(animated: true)
        dataSource.clearSearch(notifyObservers: false)
        hideKeyboard(from: picker.searchBar)
    }

    func emptyViewController(forMediaPickerController picker: WPMediaPickerViewController) -> UIViewController? {
        return searchHint
    }

    func mediaPickerControllerDidEndLoadingData(_ picker: WPMediaPickerViewController) {
        if let searchBar = picker.searchBar {
            WPStyleGuide.configureSearchBar(searchBar)
        }
    }

    func mediaPickerControllerDidCancel(_ picker: WPMediaPickerViewController) {
        picker.dismiss(animated: true)
        dataSource.clearSearch(notifyObservers: false)
        hideKeyboard(from: picker.searchBar)
    }

    func mediaPickerController(_ picker: WPMediaPickerViewController, didSelect asset: WPMediaAsset) {
        hideKeyboard(from: picker.searchBar)
    }

    func mediaPickerController(_ picker: WPMediaPickerViewController, didDeselect asset: WPMediaAsset) {
        hideKeyboard(from: picker.searchBar)
    }

    func mediaPickerController(_ picker: WPMediaPickerViewController, previewViewControllerFor assets: [WPMediaAsset], selectedIndex selected: Int) -> UIViewController? {
        return mediaPreviewHelper.previewViewController(for: assets, selectedIndex: selected)
    }

    private func hideKeyboard(from view: UIView?) {
        if let view = view, view.isFirstResponder {
            //Fix animation conflict between dismissing the keyboard and showing the accessory input view
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.01) {
                view.resignFirstResponder()
            }
        }
    }
}
