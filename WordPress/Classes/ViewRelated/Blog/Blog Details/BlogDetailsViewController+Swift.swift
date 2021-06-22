import UIKit
import SwiftUI

extension BlogDetailsViewController {
    @objc
    func showEmojiPicker() {
        guard #available(iOS 14.0, *) else {
            return
        }

        var pickerView = SiteIconPickerView()

        pickerView.onCompletion = { [weak self] image in
            self?.dismiss(animated: true, completion: nil)
            self?.headerView.updatingIcon = true
            self?.uploadDroppedSiteIcon(image, onCompletion: {})
        }

        pickerView.onDismiss = { [weak self] in
            self?.dismiss(animated: true, completion: nil)
        }

        let controller = UIHostingController(rootView: pickerView)
        present(controller, animated: true, completion: nil)
    }
}
