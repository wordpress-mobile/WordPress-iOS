import WPMediaPicker

final class StockPhotosPicker: NSObject {
    func presentPicker(origin: UIViewController) {
        let stockDataSource = StockPhotosDataSource()

        let options = WPMediaPickerOptions()
        options.showMostRecentFirst = true
        options.filter = [.all]
        options.allowCaptureOfMedia = false
        options.showSearchBar = true

        let picker = WPNavigationMediaPickerViewController()
        picker.dataSource = stockDataSource
        picker.mediaPicker.options = options
        picker.delegate = self
        picker.modalPresentationStyle = .currentContext
        origin.present(picker, animated: true)
    }
}

extension StockPhotosPicker: WPMediaPickerViewControllerDelegate {
    func mediaPickerController(_ picker: WPMediaPickerViewController, didFinishPicking assets: [WPMediaAsset]) {
        //
    }

    func emptyView(forMediaPickerController picker: WPMediaPickerViewController) -> UIView? {
        let searchHint = MediaNoResultsView()

        return searchHint
    }

    func mediaPickerControllerDidCancel(_ picker: WPMediaPickerViewController) {
        print("cancel")
    }
}
