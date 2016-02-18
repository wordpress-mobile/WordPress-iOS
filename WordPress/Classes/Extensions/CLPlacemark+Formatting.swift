import UIKit
import CoreLocation

extension CLPlacemark
{
    /// Returns a single string with the address information of a placemark formatted
    func formattedAddress() -> String? {
        guard let addressDictionary = self.addressDictionary,
              let formattedAddressLines = addressDictionary["FormattedAddressLines"] as? [String] else {
                return self.name;
        }
        if formattedAddressLines.count <= 1 {
            return formattedAddressLines.joinWithSeparator(", ")
        }
        var address = formattedAddressLines.first!
        address.appendContentsOf("\n")
        address.appendContentsOf(formattedAddressLines.suffixFrom(1).joinWithSeparator(", "))
        return address
    }
}