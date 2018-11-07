
import Foundation

// MARK: - LocationResult

struct LocationResult {
    let name: String
    let locationDescription: String
}

// MARK: - Demo support

extension LocationResult {
    static var demoResults: [LocationResult] {
        return [
            LocationResult(name: "Lilly's Lollies", locationDescription: "Hackney, London"),
            LocationResult(name: "Seaside Bowling Club", locationDescription: "Hackney, London"),
            LocationResult(name: "Bob's Diner", locationDescription: "Hackney, London"),
            LocationResult(name: "BlueSky Hair", locationDescription: "Hackney Rd, London"),
            LocationResult(name: "BlueSky Hair*", locationDescription: "Hackney Rd, London"),
        ]
    }
}
