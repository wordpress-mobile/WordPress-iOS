typealias Pattern<Element> = (Element) -> Bool

func |<Element>(lhs: @escaping Pattern<Element>, rhs: @escaping Pattern<Element>) -> Pattern<Element> {
    return { element in
        lhs(element) || rhs(element)
    }
}

func &<Element>(lhs: @escaping Pattern<Element>, rhs: @escaping Pattern<Element>) -> Pattern<Element> {
    return { element in
        lhs(element) && rhs(element)
    }
}

prefix func !<Element>(pattern: @escaping Pattern<Element>) -> Pattern<Element> {
    return { element in
        !pattern(element)
    }
}

func ~= <Element>(pattern: Pattern<Element>, element: Element) -> Bool {
    return pattern(element)
}
