/// Convenience to iterate over all possible combinations of multiple boolean values.
enum TruthTable {

    static let twoValues: [(Bool, Bool)] = [
        (true, true),
        (true, false),
        (false, true),
        (false, false)
    ]

    static let threeValues: [(Bool, Bool, Bool)] = [
        (true, true, true),
        (true, true, false),
        (true, false, true),
        (true, false, false),
        (false, true, true),
        (false, true, false),
        (false, false, true),
        (false, false, false)
    ]
}
