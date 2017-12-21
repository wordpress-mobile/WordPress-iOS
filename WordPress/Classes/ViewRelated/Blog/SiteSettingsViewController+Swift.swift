import Foundation

extension SiteSettingsViewController {

    @objc func showDateAndTimeFormatSettings() {
        let dateAndTimeFormatViewController = DateAndTimeFormatSettingsViewController(blog: blog)
        navigationController?.pushViewController(dateAndTimeFormatViewController, animated: true)
    }

    @objc func showPostPerPageSetting() {
        let pickerViewController = SettingsPickerViewController(style: .grouped)
        pickerViewController.title = NSLocalizedString("Posts per Page", comment: "Posts per Page Title")
        pickerViewController.switchVisible = false
        pickerViewController.selectionText = NSLocalizedString("The number of posts to show per page.",
                                                               comment: "Text above the selection of the number of posts to show per blog page")
        pickerViewController.pickerFormat = NSLocalizedString("%d posts", comment: "Number of posts")
        pickerViewController.pickerMinimumValue = minNumberOfPostPerPage
        if let currentValue = blog.settings?.postsPerPage as? Int {
            pickerViewController.pickerSelectedValue = currentValue
            pickerViewController.pickerMaximumValue = max(currentValue, maxNumberOfPostPerPage)
        } else {
            pickerViewController.pickerMaximumValue = maxNumberOfPostPerPage
        }
        pickerViewController.onChange           = { [weak self] (enabled: Bool, newValue: Int) in
            self?.blog.settings?.postsPerPage = newValue as NSNumber?
            self?.saveSettings()
        }

        navigationController?.pushViewController(pickerViewController, animated: true)
    }

    // MARK: Private Properties

    fileprivate var minNumberOfPostPerPage: Int { return 1 }
    fileprivate var maxNumberOfPostPerPage: Int { return 1000 }

}
