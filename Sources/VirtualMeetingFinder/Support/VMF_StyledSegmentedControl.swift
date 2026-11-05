/*
 © Copyright 2026, Little Green Viper Software Development LLC
 LICENSE:

 MIT License

 Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation
 files (the "Software"), to deal in the Software without restriction, including without limitation the rights to use, copy,
 modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the
 Software is furnished to do so, subject to the following conditions:

 The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.

 THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES
 OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT.
 IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF
 CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
 */

import UIKit

/* ###################################################################################################################################### */
// MARK: - Styled Segmented Control -
/* ###################################################################################################################################### */
/**
 Matches Recovrr's text switches: six-point outer corners and an inset rectangular selection.
 UIKit owns the labels, selection, actions, and accessibility. On iOS 26 and later,
 public background-image APIs preserve the rectangular style instead of the native capsule.
 */
class VMF_StyledSegmentedControl: UISegmentedControl {
     private var renderedSegmentSize: CGSize = .zero
     private var backgroundImagesNeedUpdate = true

     override var selectedSegmentTintColor: UIColor? {
          didSet { invalidateBackgroundImages() }
     }

     override init(frame: CGRect) {
          super.init(frame: frame)
          registerAppearanceTraits()
     }

     override init(items: [Any]?) {
          super.init(items: items)
          registerAppearanceTraits()
     }

     required init?(coder: NSCoder) {
          super.init(coder: coder)
          registerAppearanceTraits()
     }

     override func tintColorDidChange() {
          super.tintColorDidChange()
          invalidateBackgroundImages()
     }

     override func layoutSubviews() {
          let radius = min(6, bounds.height / 2)
          if #available(iOS 26.0, *) { updateBackgroundImages(cornerRadius: radius) }
          super.layoutSubviews()
          layer.cornerRadius = radius
          clipsToBounds = true
     }

     private func registerAppearanceTraits() {
          if #available(iOS 26.0, *) {
               registerForTraitChanges([UITraitUserInterfaceStyle.self, UITraitAccessibilityContrast.self, UITraitDisplayScale.self]) { (self: Self, _) in
                    self.invalidateBackgroundImages()
               }
          }
     }

     private func invalidateBackgroundImages() {
          backgroundImagesNeedUpdate = true
          setNeedsLayout()
     }

     /** Renders equal-width segment backgrounds without cropping the middle segments' corners. */
     private func updateBackgroundImages(cornerRadius inCornerRadius: CGFloat) {
          guard numberOfSegments > 0, bounds.width > 0, bounds.height > 4 else { return }
          let size = CGSize(width: max(1, bounds.width / CGFloat(numberOfSegments)), height: bounds.height)
          guard backgroundImagesNeedUpdate || size != renderedSegmentSize else { return }
          backgroundImagesNeedUpdate = false
          renderedSegmentSize = size

          backgroundColor = .tertiarySystemFill
          let selectionColor = (selectedSegmentTintColor ?? tintColor ?? .systemBlue).resolvedColor(with: traitCollection)
          let highlightColor = UIColor.label.resolvedColor(with: traitCollection).withAlphaComponent(0.08)
          let states: [UIControl.State] = [.normal, .selected, .highlighted, [.selected, .highlighted], .disabled, [.selected, .disabled]]
          let colors: [UIColor] = [.clear, selectionColor, highlightColor, selectionColor.withAlphaComponent(0.85), .clear, selectionColor.withAlphaComponent(0.45)]
          let format = UIGraphicsImageRendererFormat()
          format.scale = traitCollection.displayScale
          format.preferredRange = .standard
          let renderer = UIGraphicsImageRenderer(size: size, format: format)
          let selectionRect = CGRect(origin: .zero, size: size).insetBy(dx: 2, dy: 2)

          for (state, color) in zip(states, colors) {
               let image = renderer.image { _ in
                    color.setFill()
                    UIBezierPath(roundedRect: selectionRect, cornerRadius: max(0, inCornerRadius - 2)).fill()
               }.resizableImage(withCapInsets: .zero)
               setBackgroundImage(image, for: state, barMetrics: .default)
          }

          let dividerRenderer = UIGraphicsImageRenderer(size: CGSize(width: 1, height: size.height), format: format)
          let clearDivider = dividerRenderer.image { _ in }
          let unselectedDivider = dividerRenderer.image { context in
               UIColor.label.resolvedColor(with: traitCollection).withAlphaComponent(0.12).setFill()
               context.fill(CGRect(x: 0, y: 6, width: 1, height: max(0, size.height - 12)))
          }
          for leftState in states {
               for rightState in states {
                    let divider = leftState.contains(.selected) || rightState.contains(.selected) ? clearDivider : unselectedDivider
                    setDividerImage(divider, forLeftSegmentState: leftState, rightSegmentState: rightState, barMetrics: .default)
               }
          }
     }
}
