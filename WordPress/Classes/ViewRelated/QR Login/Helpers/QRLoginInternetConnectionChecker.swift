import Foundation
import WordPressShared

struct QRLoginInternetConnectionChecker: QRLoginConnectionChecker {

    let getConectionAvailability: () -> Bool = { ReachabilityUtils.connectionAvailable }

    var connectionAvailable: Bool { getConectionAvailability() }
}
