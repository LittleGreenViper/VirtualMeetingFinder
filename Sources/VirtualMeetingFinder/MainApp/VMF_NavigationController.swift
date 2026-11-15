/*
 © Copyright 2024-2026, Little Green Viper Software Development LLC
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

/**
 Shares navigation typography and symbols, and keeps the bar at the top on iPhone Duo.
 */
final class VMF_NavigationController: UINavigationController {
     /// Matches Recovrr's navigation titles, with WANA's adaptive accent color.
     static let titleFont = UIFont.systemFont(ofSize: 16, weight: .thin, width: UIFont.Width(0.5))
     static let buttonFont = UIFont.systemFont(ofSize: 17, weight: .regular)
     static let symbolConfiguration = UIImage.SymbolConfiguration(pointSize: 17, weight: .light, scale: .medium)
     static var accentColor: UIColor { UIColor(named: "AccentColor") ?? .systemBlue }
     static var titleAttributes: [NSAttributedString.Key: Any] {
          [.font: titleFont, .foregroundColor: accentColor, .kern: 1]
     }

     override func viewDidLoad() {
          super.viewDidLoad()

          let bar = navigationBar
          bar.tintColor = Self.accentColor
          bar.prefersLargeTitles = false

          // Preserve the existing bar backgrounds in every presentation mode.
          func styled(_ appearance: UINavigationBarAppearance) -> UINavigationBarAppearance {
               let appearance = appearance.copy()
               appearance.titleTextAttributes = Self.titleAttributes
               let backImage = UIImage(systemName: "chevron.backward", withConfiguration: Self.symbolConfiguration)
               appearance.setBackIndicatorImage(backImage, transitionMaskImage: backImage)
               for button in [appearance.buttonAppearance, appearance.doneButtonAppearance, appearance.backButtonAppearance] {
                    let attributes: [NSAttributedString.Key: Any] = [.font: Self.buttonFont, .foregroundColor: Self.accentColor]
                    button.normal.titleTextAttributes = attributes
                    button.highlighted.titleTextAttributes = attributes
                    button.disabled.titleTextAttributes = [.font: Self.buttonFont, .foregroundColor: Self.accentColor.withAlphaComponent(0.35)]
               }
               return appearance
          }

          bar.standardAppearance = styled(bar.standardAppearance)
          bar.scrollEdgeAppearance = bar.scrollEdgeAppearance.map(styled)
          bar.compactAppearance = bar.compactAppearance.map(styled)
          bar.compactScrollEdgeAppearance = bar.compactScrollEdgeAppearance.map(styled)
     }

     /// The system controls occupying one end of the horizontal bar on Duo.
     var topBarSideOcclusion: CGRect? {
          guard #available(iOS 27.1, *), traitCollection.userInterfaceIdiom == .phone,
                let window = viewIfLoaded?.window else { return nil }

          let barFrame = navigationBar.convert(navigationBar.bounds, to: window)
          return window.reservedRegions(kind: .occlusion).map(\.frame).first { frame in
               frame.minY <= barFrame.minY && frame.maxY >= barFrame.maxY
                    && frame.width < window.bounds.width
                    && (frame.minX <= window.bounds.minX || frame.maxX >= window.bounds.maxX)
          }
     }

     /// The outer display has side controls. The inner display reports a hinge even when fully open.
     var usesDuoLayout: Bool {
          guard #available(iOS 27.1, *), traitCollection.userInterfaceIdiom == .phone,
                let window = viewIfLoaded?.window else { return false }

          return topBarSideOcclusion != nil || !window.reservedRegions(kind: .division, options: .includeInactive).isEmpty
     }

     @available(iOS 27.1, *)
     override var preferredVerticalBarBehavior: UIVerticalBarBehavior { .disabled }

     @available(iOS 27.1, *)
     override var childForPreferredVerticalBarBehavior: UIViewController? { nil }
}
