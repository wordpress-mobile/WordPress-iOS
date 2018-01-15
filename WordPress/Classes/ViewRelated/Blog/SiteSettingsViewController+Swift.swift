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

    // MARK: AMP footer

    open override func tableView(_ tableView: UITableView, viewForFooterInSection section: Int) -> UIView? {
        guard isTrafficSettingsSection(section) else {
            return nil
        }

        let footer = UITableViewHeaderFooterView()
        footer.textLabel?.text = NSLocalizedString("Your WordPress.com site supports the use of Accelerated Mobile Pages, a Google-led initiative that dramatically speeds up loading times on mobile devices.",
                                                   comment: "Footer for AMP Traffic Site Setting, should match Calypso.")
        footer.textLabel?.numberOfLines = 0
        footer.textLabel?.font = UIFont.preferredFont(forTextStyle: .footnote)
        footer.textLabel?.isUserInteractionEnabled = true

        let tap = UITapGestureRecognizer(target: self, action: #selector(handleAMPFooterTap(_:)))
        footer.addGestureRecognizer(tap)
        return footer
    }

    @objc fileprivate func handleAMPFooterTap(_ sender: UITapGestureRecognizer) {
        guard let url =  URL(string: self.ampSupportURL) else {
            return
        }
        let webViewController = WebViewControllerFactory.controller(url: url)

        if presentingViewController != nil {
            navigationController?.pushViewController(webViewController, animated: true)
        } else {
            let navController = UINavigationController(rootViewController: webViewController)
            present(navController, animated: true, completion: nil)
        }
    }

    override open func tableView(_ tableView: UITableView, willDisplayFooterView view: UIView, forSection section: Int) {
        WPStyleGuide.configureTableViewSectionFooter(view)
    }

    // MARK: Private Properties

    fileprivate var minNumberOfPostPerPage: Int { return 1 }
    fileprivate var maxNumberOfPostPerPage: Int { return 1000 }
    fileprivate var ampSupportURL: String { return "https://support.wordpress.com/amp-accelerated-mobile-pages/" }

}
