protocol NotificationAction {
    func identifier() -> Identifier
    func execute()
    func enable()
    func disable()
    func setOn()
    func setOff()
}

extension NotificationAction {
    func identifier() -> Identifier {
        let typeAsString = String(describing: type(of: self))
        return Identifier(value: typeAsString)
    }

    func enable() {

    }

    func disable() {

    }

    func setOn() {

    }

    func setOff() {

    }
}
