import Foundation
import UIKit

extension MySiteViewController {

    func configureHeaderView() -> NewBlogDetailHeaderView {
        return NewBlogDetailHeaderView(items: [])
    }

}

extension MySiteViewController: BlogDetailHeaderViewDelegate {

    func siteIconTapped() {
        // TODO
    }

    func siteIconReceivedDroppedImage(_ image: UIImage?) {
        // TODO
    }

    func siteIconShouldAllowDroppedImages() -> Bool {
        // TODO
        return false
    }

    func siteTitleTapped() {
        // TODO
    }

    func siteSwitcherTapped() {
        // TODO
    }

    func visitSiteTapped() {
        // TODO
    }
}
