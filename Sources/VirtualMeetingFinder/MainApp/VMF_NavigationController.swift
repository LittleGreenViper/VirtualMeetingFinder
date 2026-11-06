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
 Keeps the app's navigation bar at the top on iPhone Duo.
 */
final class VMF_NavigationController: UINavigationController {
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
