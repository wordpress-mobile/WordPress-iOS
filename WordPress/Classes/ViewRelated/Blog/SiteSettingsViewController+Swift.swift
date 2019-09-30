import Foundation
import WordPressFlux

// This is just a wrapper for the receipts, since Receipt isn't exposed to Obj-C
@objc class TimeZoneObserver: NSObject {
    let storeReceipt: Receipt
    let queryReceipt: Receipt

    init(onStateChange callback: @escaping (TimeZoneStoreState, TimeZoneStoreState) -> Void) {
        let store = StoreContainer.shared.timezone
        storeReceipt = store.onStateChange(callback)
        queryReceipt = store.query(TimeZoneQuery())
        super.init()
    }
}

extension SiteSettingsViewController {
    @objc func observeTimeZoneStore() {
        timeZoneObserver = TimeZoneObserver() { [weak self] (oldState, newState) in
            guard let controller = self else {
                return
            }
            let oldLabel = controller.timezoneLabel(state: oldState)
            let newLabel = controller.timezoneLabel(state: newState)
            guard newLabel != oldLabel else {
                return
            }

            // If this were ImmuTable-based, I'd reload the specific row
            // But it could silently break if we change the order of rows in the future
            // @koke 2018-01-17
            controller.tableView.reloadData()
        }
    }

    @objc func timezoneLabel() -> String? {
        return timezoneLabel(state: StoreContainer.shared.timezone.state)
    }

    func timezoneLabel(state: TimeZoneStoreState) -> String? {
        guard let settings = blog.settings else {
            return nil
        }
        if let timezone = state.findTimezone(gmtOffset: settings.gmtOffset?.floatValue, timezoneString: settings.timezoneString) {
            return timezone.label
        } else {
            return timezoneValue
        }
    }

    var timezoneValue: String? {
        if let timezoneString = blog.settings?.timezoneString?.nonEmptyString() {
            return timezoneString
        } else if let gmtOffset = blog.settings?.gmtOffset {
            return OffsetTimeZone(offset: gmtOffset.floatValue).label
        } else {
            return nil
        }
    }

    @objc func showTimezoneSelector() {
        let controller = TimeZoneSelectorViewController(selectedValue: timezoneValue) { [weak self] (newValue) in
            self?.navigationController?.popViewController(animated: true)
            self?.blog.settings?.gmtOffset = newValue.gmtOffset as NSNumber?
            self?.blog.settings?.timezoneString = newValue.timezoneString
            self?.saveSettings()
        }
        navigationController?.pushViewController(controller, animated: true)
    }

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

    @objc func showSpeedUpYourSiteSettings() {
        let speedUpSiteSettingsViewController = JetpackSpeedUpSiteSettingsViewController(blog: blog)
        navigationController?.pushViewController(speedUpSiteSettingsViewController, animated: true)
    }

    // MARK: Footers

    @objc(getTrafficSettingsSectionFooterView)
    func trafficSettingsSectionFooterView() -> UIView {
        let footer = makeFooterView()
        footer.textLabel?.text = NSLocalizedString("Your WordPress.com site supports the use of Accelerated Mobile Pages, a Google-led initiative that dramatically speeds up loading times on mobile devices.",
                                                   comment: "Footer for AMP Traffic Site Setting, should match Calypso.")
        footer.textLabel?.isUserInteractionEnabled = true

        let tap = UITapGestureRecognizer(target: self, action: #selector(handleAMPFooterTap(_:)))
        footer.addGestureRecognizer(tap)
        return footer
    }

    @objc(getEditorSettingsSectionFooterView)
    func editorSettingsSectionFooterView() -> UIView {
        let footer = makeFooterView()
        footer.textLabel?.text = NSLocalizedString("Edit new posts and pages with the block editor.", comment: "Explanation for the option to enable the block editor")
        return footer
    }

    private func makeFooterView() -> UITableViewHeaderFooterView {
        let footer = UITableViewHeaderFooterView()
        footer.textLabel?.numberOfLines = 0
        footer.textLabel?.font = UIFont.preferredFont(forTextStyle: .footnote)
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
            present(navController, animated: true)
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
