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

/* ###################################################################################################################################### */
// MARK: - Day and Time Selection Popover -
/* ###################################################################################################################################### */
/**
 The popover that will host the main screen's weekday and time selection controls.
 Its contents are intentionally empty until those controls are moved from the header.
 */
class VMF_DayTimeSelectionViewController: UIViewController, UIPopoverPresentationControllerDelegate {
     /* ################################################################## */
     /**
      Sets up the empty popover using the current appearance.
      */
     override func viewDidLoad() {
          super.viewDidLoad()
          view.backgroundColor = .systemBackground
          view.accessibilityViewIsModal = true
     }

     /* ################################################################## */
     /**
      Keeps the presentation as a popover on compact screens, including iPhone.

      - parameter inController: The presentation controller (ignored).
      - returns: No adaptation to a sheet or full screen.
      */
     func adaptivePresentationStyle(for inController: UIPresentationController) -> UIModalPresentationStyle { .none }

     /* ################################################################## */
     /**
      Keeps the popover presentation when the available size changes.

      - parameter inController: The presentation controller (ignored).
      - parameter inTraitCollection: The new traits (ignored).
      - returns: No adaptation to a sheet or full screen.
      */
     func adaptivePresentationStyle(for inController: UIPresentationController, traitCollection inTraitCollection: UITraitCollection) -> UIModalPresentationStyle { .none }

     /* ################################################################## */
     /**
      Allows VoiceOver users to dismiss the empty popover with the escape gesture.

      - returns: True, because the dismissal is handled here.
      */
     override func accessibilityPerformEscape() -> Bool {
          dismiss(animated: true)
          return true
     }
}
