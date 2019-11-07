import WPMediaPicker

protocol StockPhotosPickerDelegate: AnyObject {
    func stockPhotosPicker(_ picker: StockPhotosPicker, didFinishPicking assets: [StockPhotosMedia])
}

/// Presents the Stock Photos main interface
final class StockPhotosPicker: NSObject {
    var allowMultipleSelection = true

    private lazy var dataSource: StockPhotosDataSource = {
        return StockPhotosDataSource(service: stockPhotosService)
    }()

    private lazy var stockPhotosService: StockPhotosService = {
        guard let api = self.blog?.wordPressComRestApi() else {
            //TO DO. Shall we present a user facing error (although in theory we should never reach this case if we limit Stock Photos to Jetpack blogs only)
            // At this moment, what we do is return a null implementation of the StockPhotosService. The user-facing effect will be that there are no results
            return NullStockPhotosService()
        }

        return DefaultStockPhotosService(api: api)
    }()

    weak var delegate: StockPhotosPickerDelegate?
    private var blog: Blog?
    private var observerToken: NSObjectProtocol?

    private let searchHint = NoResultsViewController.controller()

    private lazy var pickerOptions: WPMediaPickerOptions = {
        let options = WPMediaPickerOptions()
        options.showMostRecentFirst = true
        options.filter = [.all]
        options.allowCaptureOfMedia = false
        options.showSearchBar = true
        options.preferredStatusBarStyle = .lightContent
        options.allowMultipleSelection = allowMultipleSelection
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
        NoResultsStockPhotosConfiguration.configureAsIntro(searchHint)
        self.blog = blog

        origin.present(picker, animated: true) {
            self.picker.mediaPicker.searchBar?.becomeFirstResponder()
        }

        observeDataSource()
        trackAccess()
    }

    private func observeDataSource() {
        observerToken = dataSource.registerChangeObserverBlock { [weak self] (_, _, _, _, assets) in
            self?.updateHintView()
        }
        dataSource.onStartLoading = { [weak self] in
            if let searchHint = self?.searchHint {
                NoResultsStockPhotosConfiguration.configureAsLoading(searchHint)
            }
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
            NoResultsStockPhotosConfiguration.configure(searchHint)
        } else {
            NoResultsStockPhotosConfiguration.configureAsIntro(searchHint)
        }
    }

    deinit {
        if let token = observerToken {
            dataSource.unregisterChangeObserver(token)
        }
    }
}

extension StockPhotosPicker: WPMediaPickerViewControllerDelegate {
    func mediaPickerController(_ picker: WPMediaPickerViewController, didFinishPicking assets: [WPMediaAsset]) {
        guard let stockPhotosMedia = assets as? [StockPhotosMedia] else {
            assertionFailure("assets should be of type `[StockPhotosMedia]`")
            return
        }
        delegate?.stockPhotosPicker(self, didFinishPicking: stockPhotosMedia)
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

    private func hideKeyboard(from view: UIView?) {
        if let view = view, view.isFirstResponder {
            //Fix animation conflict between dismissing the keyboard and showing the accessory input view
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.01) {
                view.resignFirstResponder()
            }
        }
    }
}

// MARK: - Tracks
extension StockPhotosPicker {
    fileprivate func trackAccess() {
        WPAnalytics.track(.stockMediaAccessed)
    }
}
