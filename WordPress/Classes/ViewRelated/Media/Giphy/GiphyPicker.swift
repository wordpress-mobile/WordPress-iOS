import WPMediaPicker

protocol GiphyPickerDelegate: AnyObject {
}

/// Presents the Giphy main interface
final class GiphyPicker: NSObject {
    private lazy var dataSource: GiphyDataSource = {
        return GiphyDataSource()
    }()

    weak var delegate: GiphyPickerDelegate?
    private var blog: Blog?

    private let searchHint = NoResultsViewController.controller()

    private var pickerOptions: WPMediaPickerOptions = {
        let options = WPMediaPickerOptions()
        options.showMostRecentFirst = true
        options.filter = [.all]
        options.allowCaptureOfMedia = false
        options.showSearchBar = true
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
}

extension GiphyPicker: WPMediaPickerViewControllerDelegate {
    func mediaPickerController(_ picker: WPMediaPickerViewController, didFinishPicking assets: [WPMediaAsset]) {
        guard let _ = assets as? [GiphyMedia] else {
            assertionFailure("assets should be of type `[GiphyMedia]`")
            return
        }
        // TODO: Notify delegate that assets were picked
        picker.dismiss(animated: true)
        // TODO: Clear data source search
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
        // TODO: Clear data source search
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
