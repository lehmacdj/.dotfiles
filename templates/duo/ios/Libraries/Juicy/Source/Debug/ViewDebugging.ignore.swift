/// These are some private UIKit methods that are available for debugging purposes
@objc public protocol UIViewPrivate {
    func recursiveDescription() -> String
    func _autolayoutTrace() -> String
}

public extension UIView {
    var recursiveDescription: String {
        (self as AnyObject).recursiveDescription()
    }

    var _autolayoutTrace: String {
        (self as AnyObject)._autolayoutTrace()
    }

    func addOutline(_ color: UIColor? = nil, width: CGFloat = 2.0) -> Self {
        let color = color ?? UIColor(hex: .random(in: 0x000000...0xFFFFFF))
        self.layer.borderColor = color.cgColor
        self.layer.borderWidth = width
        return self
    }
}
