import Foundation

struct JetpackScanThreatSectionGrouping {
    public var sections: [JetpackThreatSection]?

    init(threats: [JetpackScanThreat], siteRef: JetpackSiteRef) {
        let grouping: [DateComponents: [JetpackScanThreat]] = Dictionary(grouping: threats) { (threat) -> DateComponents in
            return Calendar.current.dateComponents([.day, .year, .month], from: threat.firstDetected)
        }

        let keys = grouping.keys
        let formatter = ActivityDateFormatting.longDateFormatter(for: siteRef, withTime: false)
        var sectionsArray: [JetpackThreatSection] = []
        for key in keys {
            guard let date = Calendar.current.date(from: key),
                  let threats = grouping[key]
            else {
                continue
            }

            let title = formatter.string(from: date)
            sectionsArray.append(JetpackThreatSection(title: title, date: date, threats: threats))
        }

        self.sections = sectionsArray.sorted(by: { $0.date > $1.date })
    }
}
