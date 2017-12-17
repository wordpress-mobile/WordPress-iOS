import Foundation

extension SiteSettingsViewController {

    @objc func showTimeZoneSelector() {
        let onChange = { [weak self] (selectedVal: TimeZoneSelected) in
            self?.navigationController?.popViewController(animated: true)
            switch selectedVal {
            case .manualOffset(let manualOffset):
                self?.blog.settings?.timeZoneString = ""
                self?.blog.settings?.gmtOffset = manualOffset
            case .timeZoneString(let timeZoneString):
                self?.blog.settings?.timeZoneString = timeZoneString as NSString
                self?.blog.settings?.gmtOffset = nil
            }
            self?.saveSettings()
        }
        let selectedTimeZone = TimeZoneSelected.init(timeZoneString: self.blog.settings?.timeZoneString as String?,
                                                     manualOffset: self.blog.settings?.gmtOffset)
        let vc = TimeZoneSelectorViewController(timeZoneSelected: selectedTimeZone,
                                                onChange: onChange)
        self.navigationController?.pushViewController(vc, animated: true)
    }

}
