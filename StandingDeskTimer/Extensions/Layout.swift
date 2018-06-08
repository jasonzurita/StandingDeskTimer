import AppKit

typealias Constraint = (_ child: NSView, _ parent: NSView) -> NSLayoutConstraint

func constant<Anchor>(_ keyPath: KeyPath<NSView, Anchor>, constant: CGFloat) -> Constraint where Anchor: NSLayoutDimension {
    return { view, parent in
        view[keyPath: keyPath].constraint(equalToConstant: constant)
    }
}

func equal<Axis, Anchor>(_ keyPath: KeyPath<NSView, Anchor>, _ to: KeyPath<NSView, Anchor>, constant: CGFloat = 0) -> Constraint where Anchor: NSLayoutAnchor<Axis> {
    return { view, parent in
        view[keyPath: keyPath].constraint(equalTo: parent[keyPath: to], constant: constant)
    }
}

func equal<Axis, Anchor>(_ keyPath: KeyPath<NSView, Anchor>, constant: CGFloat = 0) -> Constraint where Anchor: NSLayoutAnchor<Axis> {
    return equal(keyPath, keyPath, constant: constant)
}

extension NSView {
    func addSubview(_ child: NSView, constraints: [Constraint]) {
        addSubview(child)
        child.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate(constraints.map { $0(child, self) })
    }
}
