import SwiftUI

extension Image {
    init(dashicon: String?) {
        self.init(systemName: systemName(forDashicon: dashicon))
    }
}

extension UIImage {
    convenience init?(dashicon: String?) {
        self.init(systemName: systemName(forDashicon: dashicon))
    }
}

private func systemName(forDashicon dashicon: String?) -> String {
    let fallback = "doc.richtext"
    guard let dashicon, dashicon.hasPrefix("dashicons-") else {
        return fallback
    }

    let icon = dashicon.removingPrefix("dashicons-")
    return mapping[icon] ?? fallback
}

private let mapping: [String: String] = [
    // Commerce & Products
    "products": "shippingbox",
    "archive": "archivebox",
    "cart": "cart",
    "store": "storefront",
    "money": "dollarsign.circle",
    "money-alt": "dollarsign.circle",
    "award": "rosette",
    "tickets": "ticket",
    "tickets-alt": "ticket",

    // Events & Scheduling
    "calendar": "calendar",
    "calendar-alt": "calendar",
    "clock": "clock",
    "location": "mappin",
    "location-alt": "mappin",

    // Creative & Portfolio
    "art": "paintbrush",
    "portfolio": "rectangle.stack",
    "images-alt": "photo.on.rectangle.angled",
    "images-alt2": "photo.on.rectangle.angled",
    "format-gallery": "photo.on.rectangle.angled",
    "format-image": "photo",
    "format-video": "video",
    "format-audio": "music.note",
    "camera": "camera",
    "album": "square.stack",

    // People & Business
    "businessman": "person",
    "businesswoman": "person",
    "businessperson": "person",
    "groups": "person.3",
    "testimonial": "quote.bubble",
    "building": "building.2",
    "id": "person.text.rectangle",
    "id-alt": "person.text.rectangle",

    // Education & Content
    "book": "book",
    "book-alt": "book",
    "lightbulb": "lightbulb",
    "slides": "rectangle.on.rectangle",
    "clipboard": "doc.on.clipboard",
    "media-document": "doc",
    "text-page": "doc.text",

    // Communication
    "megaphone": "megaphone",
    "email": "envelope",
    "email-alt": "envelope",
    "phone": "phone",
    "microphone": "mic",
    "format-quote": "quote.bubble",

    // Miscellaneous
    "food": "fork.knife",
    "heart": "heart",
    "star-filled": "star.fill",
    "star-empty": "star",
    "flag": "flag",
    "tag": "tag",
    "hammer": "hammer",
    "car": "car",
    "airplane": "airplane",
    "pets": "pawprint",
    "games": "gamecontroller",
    "admin-home": "house",
    "admin-page": "doc",
]

#Preview {
    ScrollView {
        LazyVGrid(columns: [GridItem(.adaptive(minimum: 80))], spacing: 16) {
            ForEach(mapping.keys.sorted(), id: \.self) { key in
                VStack(spacing: 8) {
                    Image(systemName: mapping[key]!)
                        .font(.title)
                    Text(key)
                        .font(.caption)
                        .multilineTextAlignment(.center)
                }
                .frame(maxWidth: .infinity)
            }
        }
        .padding()
    }
}
