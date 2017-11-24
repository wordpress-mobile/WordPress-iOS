import UIKit
import CoreLocation

extension CLPlacemark {
    /// Returns a single string with the address information of a placemark formatted
    @objc func formattedAddress() -> String? {
        guard let addressDictionary = self.addressDictionary,
              let formattedAddressLines = addressDictionary["FormattedAddressLines"] as? [String] else {
                return self.name
        }
        if formattedAddressLines.count <= 1 {
            return formattedAddressLines.joined(separator: ", ")
        }
        var address = formattedAddressLines.first!
        address.append("\n")
        address.append(formattedAddressLines.suffix(from: 1).joined(separator: ", "))
        return address
    }
}
