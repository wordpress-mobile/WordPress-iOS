extension UIView {

    /// Call this method to get any existing constraint for the specified axis and the specified relation.
    ///
    /// - Parameters:
    ///     - axis: the axis for the first element in the constraint.
    ///     - relation: the relation for the constraint
    ///
    /// - Returns: the existing constraint or `nil` if no matching constraint exists.
    ///
    func constraint(for axis: NSLayoutConstraint.Attribute, withRelation relation: NSLayoutConstraint.Relation) -> NSLayoutConstraint? {

        return constraints.first(where: { constraint -> Bool in
            return constraint.firstAttribute == axis && constraint.relation == relation
        })
    }

    /// Call this method to update a constraint for this view without duplicating it.  If the constraint
    /// exists it will be updated, but if it doesn't it will be added.
    ///
    /// - Parameters:
    ///     - axis: the axis for the first element in the constraint.  This is part of the matching criteria.
    ///     - relation: the relation for the constraint.  This is part of the matching criteria.
    ///     - constant: the new constant for the constraint.
    ///     - active: whether the constraint must be activated or deactivated.
    ///
    func updateConstraint(for axis: NSLayoutConstraint.Attribute, withRelation relation: NSLayoutConstraint.Relation, setConstant constant: CGFloat, setActive active: Bool) {

        if let existingConstraint = constraint(for: .height, withRelation: .equal) {
            existingConstraint.constant = constant
            existingConstraint.isActive = active
        } else {
            heightAnchor.constraint(equalToConstant: constant).isActive = active
        }
    }
}
