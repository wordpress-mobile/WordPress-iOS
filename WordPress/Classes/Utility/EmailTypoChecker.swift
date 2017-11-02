import Foundation

private let knownDomains = Set([
    /* Default domains included */
    "aol.com", "att.net", "comcast.net", "facebook.com", "gmail.com", "gmx.com", "googlemail.com",
    "google.com", "hotmail.com", "hotmail.co.uk", "mac.com", "me.com", "msn.com",
    "live.com", "sbcglobal.net", "verizon.net", "yahoo.com", "yahoo.co.uk",

    /* Other global domains */
    "games.com" /* AOL */, "gmx.net", "hush.com", "hushmail.com", "icloud.com", "inbox.com",
    "lavabit.com", "love.com" /* AOL */, "outlook.com", "pobox.com", "rocketmail.com" /* Yahoo */,
    "safe-mail.net", "wow.com" /* AOL */, "ygm.com" /* AOL */, "ymail.com" /* Yahoo */, "zoho.com", "fastmail.fm",
    "yandex.com",

    /* United States ISP domains */
    "bellsouth.net", "charter.net", "comcast.com", "cox.net", "earthlink.net", "juno.com",

    /* British ISP domains */
    "btinternet.com", "virginmedia.com", "blueyonder.co.uk", "freeserve.co.uk", "live.co.uk",
    "ntlworld.com", "o2.co.uk", "orange.net", "sky.com", "talktalk.co.uk", "tiscali.co.uk",
    "virgin.net", "wanadoo.co.uk", "bt.com",

    /* Domains used in Asia */
    "sina.com", "qq.com", "naver.com", "hanmail.net", "daum.net", "nate.com", "yahoo.co.jp", "yahoo.co.kr", "yahoo.co.id", "yahoo.co.in", "yahoo.com.sg", "yahoo.com.ph",

    /* French ISP domains */
    "hotmail.fr", "live.fr", "laposte.net", "yahoo.fr", "wanadoo.fr", "orange.fr", "gmx.fr", "sfr.fr", "neuf.fr", "free.fr",

    /* German ISP domains */
    "gmx.de", "hotmail.de", "live.de", "online.de", "t-online.de" /* T-Mobile */, "web.de", "yahoo.de",

    /* Russian ISP domains */
    "mail.ru", "rambler.ru", "yandex.ru", "ya.ru", "list.ru",

    /* Belgian ISP domains */
    "hotmail.be", "live.be", "skynet.be", "voo.be", "tvcablenet.be", "telenet.be",

    /* Argentinian ISP domains */
    "hotmail.com.ar", "live.com.ar", "yahoo.com.ar", "fibertel.com.ar", "speedy.com.ar", "arnet.com.ar",

    /* Domains used in Mexico */
    "hotmail.com", "gmail.com", "yahoo.com.mx", "live.com.mx", "yahoo.com", "hotmail.es", "live.com", "hotmail.com.mx", "prodigy.net.mx", "msn.com"
    ])

/// Provides suggestions to fix common typos on email addresses.
///
/// It tries to match the email domain with a list of popular hosting providers,
/// and suggest a correction if it looks like a typo.
///
open class EmailTypoChecker: NSObject {
    /// Suggest a correction to a typo in the given email address.
    ///
    /// If it doesn't detect any typo, it returns the given email.
    ///
    @objc(guessCorrectionForEmail:)
    open static func guessCorrection(email: String) -> String {
        let components = email.components(separatedBy: "@")
        guard components.count == 2 else {
            return email
        }
        let (account, domain) = (components[0], components[1])

        // If the domain name is empty, don't try to suggest anything
        guard !domain.isEmpty else {
            return email
        }

        // If the domain name is too long, don't try suggestion (resource consuming and useless)
        guard domain.count < lengthOfLongestKnownDomain() + 1 else {
            return email
        }

        let suggestedDomain = suggest(domain)
        return account + "@" + suggestedDomain
    }
}

private func suggest(_ word: String) -> String {
    if knownDomains.contains(word) {
        return word
    }

    let candidates = edits(word).filter({ knownDomains.contains($0) })
    return candidates.first ?? word
}

private func edits(_ word: String) -> [String] {
    // deletes
    let deleted = deletes(word)
    let transposed = transposes(word)
    let replaced = alphabet.flatMap({ character in
        return replaces(character, ys: word)
    })
    let inserted = alphabet.flatMap({ character in
        return between(character, ys: word)
    })

    return deleted + transposed + replaced + inserted
}

private func deletes(_ word: String) -> [String] {
    return word.indices.map({ word.removing(at: $0) })
}

private func transposes(_ word: String) -> [String] {
    return word.indices.flatMap({ index in
        let (i, j) = (index, word.index(after: index))
        guard j < word.endIndex else {
            return nil
        }
        var copy = word
        copy.replaceSubrange(i...j, with: String(word[j]) + String(word[i]))
        return copy
    })
}

private func replaces(_ x: Character, ys: String) -> [String] {
    guard let head = ys.first else {
        return [String(x)]
    }
    let tail = ys.dropFirst()
    return [String(x) + String(tail)] + replaces(x, ys: String(tail)).map({ String(head) + $0 })
}

private func between(_ x: Character, ys: String) -> [String] {
    guard let head = ys.first else {
        return [String(x)]
    }
    let tail = ys.dropFirst()
    return [String(x) + String(ys)] + between(x, ys: String(tail)).map({ String(head) + $0 })
}

private let alphabet = "abcdefghijklmnopqrstuvwxyz"

private func lengthOfLongestKnownDomain() -> Int {
    return knownDomains.map({ $0.count }).max() ?? 0
}
