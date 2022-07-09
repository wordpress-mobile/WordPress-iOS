import Foundation

@objc extension PageSettingsViewController {

    convenience init(page: Page) {
        self.init(post: page)
    }

}
