import WPMediaPicker

final class StockPhotosPicker: NSObject {
//    private lazy var dataSource: StockPhotosDataSource = {
//        return StockPhotosDataSource()
//    }()

    private let dataSource = StockPhotosDataSource()

    func presentPicker(origin: UIViewController) {
//        let options = WPMediaPickerOptions()
//        options.showMostRecentFirst = true
//        options.filter = [.all]
//        options.allowCaptureOfMedia = false
//        options.showSearchBar = true

        let picker = WPMediaPickerViewController()
        picker.dataSource = dataSource
//        picker.mediaPicker.options = options
//        picker.view.backgroundColor = .red
        picker.mediaPickerDelegate = self
//        picker.startOnGroupSelector = false
//        picker.showGroupSelector = false
//        picker.selectionActionTitle = "Cesar"
//        picker.modalPresentationStyle = .currentContext
        origin.present(picker, animated: true)
    }
}

extension StockPhotosPicker: WPMediaPickerViewControllerDelegate {
    func mediaPickerController(_ picker: WPMediaPickerViewController, didFinishPicking assets: [WPMediaAsset]) {
        //
    }

    func emptyView(forMediaPickerController picker: WPMediaPickerViewController) -> UIView? {
        let searchHint = StockPhotosPlaceholder()

        return searchHint
    }

    func mediaPickerControllerDidCancel(_ picker: WPMediaPickerViewController) {
        print("cancel")
    }
}
