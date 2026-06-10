import UIKit
import WordPressData

// MARK: - MediaPickerMenu (Stock Photo)

extension MediaPickerMenu {
    func makeStockPhotos(blog: Blog, delegate: ExternalMediaPickerViewDelegate) -> UIAction? {
        guard MediaPickerSource.freePhotos(blog: blog).isEnabled else {
            return nil
        }
        return UIAction(
            title: Strings.pickFromStockPhotos,
            image: UIImage(systemName: "photo.on.rectangle"),
            attributes: [],
            handler: { _ in showStockPhotosPicker(blog: blog, delegate: delegate) }
        )
    }

    func showStockPhotosPicker(blog: Blog, delegate: ExternalMediaPickerViewDelegate) {
        guard let presentingViewController,
            let api = blog.wordPressComRestApi
        else {
            return
        }

        let picker = ExternalMediaPickerViewController(
            dataSource: StockPhotosDataSource(service: DefaultStockPhotosService(api: api)),
            source: .stockPhotos,
            allowsMultipleSelection: isMultipleSelectionEnabled
        )
        picker.title = Strings.pickFromStockPhotos
        picker.welcomeView = StockPhotosWelcomeView()
        picker.delegate = delegate

        let navigation = UINavigationController(rootViewController: picker)
        presentingViewController.present(navigation, animated: true)
    }
}

private enum Strings {
    static let pickFromStockPhotos = NSLocalizedString(
        "mediaPicker.pickFromStockPhotos",
        value: "Free Photo Library",
        comment: "The name of the action in the context menu for selecting photos from free stock photos"
    )
}
