// MARK: Generated accessors for contentDiffs
//
extension RevisionDiff {
    @objc(addContentDiffsObject:)
    @NSManaged public func addToContentDiffs(_ value: DiffContentValue)

    @objc(removeContentDiffsObject:)
    @NSManaged public func removeFromContentDiffs(_ value: DiffContentValue)

    @objc(addContentDiffs:)
    @NSManaged public func addToContentDiffs(_ values: NSSet)

    @objc(removeContentDiffs:)
    @NSManaged public func removeFromContentDiffs(_ values: NSSet)
}


// MARK: Generated accessors for titleDiffs
//
extension RevisionDiff {
    @objc(addTitleDiffsObject:)
    @NSManaged public func addToTitleDiffs(_ value: DiffTitleValue)

    @objc(removeTitleDiffsObject:)
    @NSManaged public func removeFromTitleDiffs(_ value: DiffTitleValue)

    @objc(addTitleDiffs:)
    @NSManaged public func addToTitleDiffs(_ values: NSSet)

    @objc(removeTitleDiffs:)
    @NSManaged public func removeFromTitleDiffs(_ values: NSSet)
}


extension RevisionDiff {
    func remove<T: DiffAbstractValue>(_ type: T.Type) -> RevisionDiff {
        guard let set = (type is DiffContentValue.Type ? contentDiffs : titleDiffs) else {
            return self
        }

        switch type {
        case is DiffContentValue.Type:
            removeFromContentDiffs(set)
        case is DiffTitleValue.Type:
            removeFromTitleDiffs(set)
        default:
            break
        }

        return self
    }

    func add<T: Codable, D: DiffAbstractValue>(values: [T], _ transform: (Int, T) -> D) {
        var array: [D] = []
        for (index, value) in values.enumerated() {
            array.append(transform(index, value))
        }

        let set = NSSet(array: array)

        switch D.self {
        case is DiffContentValue.Type:
            addToContentDiffs(set)
        case is DiffTitleValue.Type:
            addToTitleDiffs(set)
        default:
            break
        }
    }
}
