import Foundation

extension SiteSettingsViewController {

    @objc func showTimeZoneSelector() {
        let onChange = { [weak self] (timeZoneString: String, manualOffset: NSNumber?) in
            self?.navigationController?.popViewController(animated: true)
            if (manualOffset == nil) {
                self?.blog.settings?.timeZoneString = timeZoneString as NSString
            } else {
                self?.blog.settings?.timeZoneString = ""
            }
            self?.blog.settings?.gmtOffset = manualOffset
            self?.saveSettings()
        }
        let timeZoneString: String = (self.blog.settings?.timeZoneString ?? "") as String
        let vc = TimeZoneSelectorViewController(timeZoneString: timeZoneString, manualOffset: self.blog.settings?.gmtOffset, onChange: onChange)
        self.navigationController?.pushViewController(vc, animated: true)
    }

}
