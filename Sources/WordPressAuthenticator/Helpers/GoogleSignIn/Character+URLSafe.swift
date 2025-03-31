extension Character {

    // From the docs: using the unreserved characters [A-Z] / [a-z] / [0-9] / "-" / "." / "_" / "~"
    // That is, URL safe characters.
    //
    // Notice that Swift offers `CharacterSet.urlQueryAllowed` to represent this set of characters.
    // However, there is no straightforward way to convert a `CharacterSet` to a `Set<Character>`.
    // See for example https://nshipster.com/characterset/.
    static let urlSafeCharacters = Set("abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789-._~")
}
