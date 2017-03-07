import UIKit
import WPMediaPicker

class MediaLibraryViewController: UIViewController {
    let blog: Blog

    private let pickerViewController: WPMediaPickerViewController
    private let pickerDataSource: MediaLibraryPickerDataSource

    init(blog: Blog) {
        self.blog = blog
        self.pickerViewController = WPMediaPickerViewController()
        self.pickerDataSource = MediaLibraryPickerDataSource(blog: blog)

        super.init(nibName: nil, bundle: nil)

        configurePickerViewController()
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func configurePickerViewController() {
        pickerViewController.mediaPickerDelegate = self
        pickerViewController.allowCaptureOfMedia = false
        pickerViewController.filter = .all
        pickerViewController.allowMultipleSelection = false
        pickerViewController.showMostRecentFirst = true
        pickerViewController.dataSource = pickerDataSource
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        title = NSLocalizedString("Media", comment: "")
        navigationItem.backBarButtonItem?.title = ""

        addMediaPickerAsChildViewController()
    }

    private func addMediaPickerAsChildViewController() {
        pickerViewController.willMove(toParentViewController: self)
        pickerViewController.view.bounds = view.bounds
        view.addSubview(pickerViewController.view)
        addChildViewController(pickerViewController)
        pickerViewController.didMove(toParentViewController: self)
    }
}

extension MediaLibraryViewController: WPMediaPickerViewControllerDelegate {
    func mediaPickerController(_ picker: WPMediaPickerViewController, didFinishPickingAssets assets: [Any]) {

    }
}
