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
import SwiftBMLSDK
import RVS_Generic_Swift_Toolbox

/* ###################################################################################################################################### */
// MARK: - Base View Controller for All Views -
/* ###################################################################################################################################### */
/**
 Shared navigation styling, localization, and haptic feedback for storyboard screens.
 The programmatic day/time popover inherits directly from `UIViewController`.
 */
class VMF_BaseViewController: UIViewController {
     /* ################################################################## */
     /**
      The plain replacement for the system Back button on iOS 26 and later.
      */
     private var _plainBackBarButtonItem: UIBarButtonItem?

     /* ################################################################## */
     /**
      The navigation controller's gesture delegate, restored when this screen disappears.
      */
     private weak var _interactivePopGestureDelegate: UIGestureRecognizerDelegate?
     
     /* ################################################################## */
     /**
      Provides impact haptic feedback.
      */
     var feedbackGenerator: UIImpactFeedbackGenerator?
     
     /* ################################################################## */
     /**
      Provides success notification haptic feedback.
      */
     var notificationGenerator: UINotificationFeedbackGenerator?
     
     /* ################################################################## */
     /**
      Provides subtle selection haptic feedback.
      */
     var selectionGenerator: UISelectionFeedbackGenerator?
}

/* ###################################################################################################################################### */
// MARK: UIGestureRecognizerDelegate Conformance
/* ###################################################################################################################################### */
extension VMF_BaseViewController: UIGestureRecognizerDelegate {
     /* ################################################################## */
     /**
      Allows swiping back only from a settled screen with a preceding navigation entry.

      - parameter inGestureRecognizer: The navigation controller's edge swipe recognizer.
      - returns: True, if a back navigation can begin.
      */
     func gestureRecognizerShouldBegin(_ inGestureRecognizer: UIGestureRecognizer) -> Bool {
          guard let navigationController = navigationController else { return false }
          return inGestureRecognizer === navigationController.interactivePopGestureRecognizer
               && navigationController.topViewController === self
               && 1 < navigationController.viewControllers.count
               && nil == navigationController.transitionCoordinator
     }
}

/* ###################################################################################################################################### */
// MARK: Instance Methods
/* ###################################################################################################################################### */
extension VMF_BaseViewController {
     /* ################################################################## */
     /**
      This converts a 1 == Sun format into a localized weekday index (1 ... 7)
      
      - parameter inWeekdayIndex: A Sunday-based weekday (1 through 7).
      - returns: The 1-based weekday index for the local system.
      */
     func mapWeekday(_ inWeekdayIndex: Int) -> Int {
          guard (1..<8).contains(inWeekdayIndex) else { return 0 }
          var weekdayIndex = (inWeekdayIndex - Calendar.current.firstWeekday)
          
          if 0 > weekdayIndex {
               weekdayIndex += 7
          }
          
          return weekdayIndex + 1
     }
     
     /* ################################################################## */
     /**
      This converts the selected localized weekday into the 1 == Sun format needed for the meeting data.
      
      - parameter inWeekdayIndex: A weekday position (1 through 7), starting with the user's first weekday.
      - returns: The 1-based weekday index for 1 = Sunday
      */
     func unMapWeekday(_ inWeekdayIndex: Int) -> Int {
          guard (1..<8).contains(inWeekdayIndex) else { return 0 }
          
          let firstDay = Calendar.current.firstWeekday
          
          var weekdayIndex = (firstDay + inWeekdayIndex) - 1
          
          if 7 < weekdayIndex {
               weekdayIndex -= 7
          }
          
          return weekdayIndex
     }
     
     /* ################################################################## */
     /**
      This returns a string, with the localized timezone name for the meeting.
      It is not set, if the timezone is ours.
      
      - parameter inMeeting: The meeting instance.
      - returns: The timezone string.
      */
     func getMeetingTimeZone(_ inMeeting: MeetingInstance) -> String {
         guard TimeZone.current.identifier != inMeeting.timeZone.identifier,
               let zoneName = inMeeting.timeZone.localizedName(for: .standard, locale: .current),
               !zoneName.isEmpty
         else { return "" }
         
         let nativeTime = inMeeting.nextOccurrenceDateFast()
         
         let formatter = DateFormatter()
         formatter.locale = .current
         formatter.timeZone = inMeeting.timeZone
         formatter.dateStyle = .none
         formatter.timeStyle = .short
         
         let nativeTimeString = formatter.string(from: nativeTime)
         
         return String(
             format: "SLUG-TIMEZONE-FORMAT".localizedVariant,
             zoneName,
             nativeTimeString
         )
     }
}

/* ###################################################################################################################################### */
// MARK: Base Class Overrides
/* ###################################################################################################################################### */
extension VMF_BaseViewController {
     /* ################################################################## */
     /**
      Called when the view hierarchy is complete.
      We use this to set the background image and prep our haptics.
      */
     override func viewDidLoad() {
          super.viewDidLoad()
          let backgroundView = UIImageView(image: UIImage(named: "BackgroundGradient"))
          backgroundView.frame = view.bounds
          backgroundView.contentMode = .scaleToFill
          backgroundView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
          view.insertSubview(backgroundView, at: 0)

          navigationController?.navigationBar.tintColor = UIColor(named: "AccentColor")
          view?.tintColor = UIColor(named: "AccentColor")
          navigationController?.isToolbarHidden = true
          removeNavigationBarItemBackgrounds()
          feedbackGenerator = UIImpactFeedbackGenerator(style: .rigid)
          feedbackGenerator?.prepare()
          selectionGenerator = UISelectionFeedbackGenerator()
          selectionGenerator?.prepare()
          notificationGenerator = UINotificationFeedbackGenerator()
          notificationGenerator?.prepare()
     }
     
     /* ################################################################## */
     /**
      Called after the view hierarchy layout is complete.
      We use this to enforce localized accessibility.
      */
     override func viewDidLayoutSubviews() {
          super.viewDidLayoutSubviews()
          navigationItem.backButtonTitle = "SLUG-BACK".localizedVariant
          removeNavigationBarItemBackgrounds()
          accessorizer()
     }
     
     /* ################################################################## */
     /**
      Called just before the view is to appear.
      
      - parameter inIsAnimated: True, if the appearance is animated.
      */
     override func viewWillAppear(_ inIsAnimated: Bool) {
          super.viewWillAppear(inIsAnimated)
          navigationItem.title = navigationItem.title?.localizedVariant ?? title?.localizedVariant
     }

     /* ################################################################## */
     /**
      Called after each screen has finished its viewWillAppear setup, before it is displayed.

      - parameter inIsAnimated: True, if the appearance is animated.
      */
     override func viewIsAppearing(_ inIsAnimated: Bool) {
          super.viewIsAppearing(inIsAnimated)
          removeNavigationBarItemBackgrounds()
     }

     /* ################################################################## */
     /**
      Keeps the edge swipe available when using our plain Back button.

      - parameter inIsAnimated: True, if the appearance is animated.
      */
     override func viewDidAppear(_ inIsAnimated: Bool) {
          super.viewDidAppear(inIsAnimated)
          guard nil != _plainBackBarButtonItem,
                navigationController?.topViewController === self,
                let gesture = navigationController?.interactivePopGestureRecognizer,
                gesture.delegate !== self
          else { return }

          _interactivePopGestureDelegate = gesture.delegate
          gesture.delegate = self
     }

     /* ################################################################## */
     /**
      Restores the navigation controller's gesture handling before leaving this screen.

      - parameter inIsAnimated: True, if the disappearance is animated.
      */
     override func viewWillDisappear(_ inIsAnimated: Bool) {
          super.viewWillDisappear(inIsAnimated)
          if let gesture = navigationController?.interactivePopGestureRecognizer,
             gesture.delegate === self {
               gesture.delegate = _interactivePopGestureDelegate
               _interactivePopGestureDelegate = nil
          }
     }
}

/* ###################################################################################################################################### */
// MARK: Instance Methods
/* ###################################################################################################################################### */
extension VMF_BaseViewController {
     /* ################################################################## */
     /**
      Removes the Liquid Glass backgrounds from navigation bar buttons on iOS 26 and later.
      */
     func removeNavigationBarItemBackgrounds() {
          guard #available(iOS 26.0, *) else { return }

          _setUpPlainBackButton()

          // During a push, the bar's item stack may not contain this screen's item yet.
          let navigationItems = [navigationItem] + (navigationController?.navigationBar.items ?? [])
          navigationItems.forEach { item in
               item.backBarButtonItem?.hidesSharedBackground = true

               var barButtons = (item.leftBarButtonItems ?? []) + (item.rightBarButtonItems ?? [])
               var groups = item.leadingItemGroups + item.centerItemGroups + item.trailingItemGroups
               if let pinnedGroup = item.pinnedTrailingGroup {
                    groups.append(pinnedGroup)
               }
               groups.forEach { group in
                    barButtons.append(contentsOf: group.barButtonItems)
                    if let representativeItem = group.representativeItem {
                         barButtons.append(representativeItem)
                    }
               }
               barButtons.forEach { $0.hidesSharedBackground = true }
          }
     }

     /* ################################################################## */
     /**
      Replaces the native Back control, which ignores hidesSharedBackground, without replacing other left buttons.
      */
     @available(iOS 26.0, *)
     private func _setUpPlainBackButton() {
          guard let navigationController = navigationController,
                let index = navigationController.viewControllers.firstIndex(of: self),
                0 < index
          else { return }

          let leftButtons = navigationItem.leftBarButtonItems ?? []
          if nil == _plainBackBarButtonItem {
               guard !navigationItem.hidesBackButton,
                     leftButtons.isEmpty || navigationItem.leftItemsSupplementBackButton
               else { return }

               let backButton = UIBarButtonItem(image: UIImage(systemName: "chevron.backward"),
                                                style: .plain,
                                                target: self,
                                                action: #selector(_goBack))
               backButton.accessibilityLabel = "SLUG-BACK".localizedVariant
               backButton.accessibilityHint = "SLUG-ACC-BACK-HINT".localizedVariant
               backButton.hidesSharedBackground = true
               backButton.menu = UIMenu(children: navigationController.viewControllers[..<index].reversed().map { controller in
                    UIAction(title: controller.navigationItem.title ?? controller.title ?? "SLUG-BACK".localizedVariant) { [weak navigationController, weak controller] _ in
                         guard let controller = controller else { return }
                         navigationController?.popToViewController(controller, animated: true)
                    }
               })
               _plainBackBarButtonItem = backButton
          }

          guard let backButton = _plainBackBarButtonItem else { return }
          navigationItem.hidesBackButton = true
          if !leftButtons.contains(where: { $0 === backButton }) {
               navigationItem.leftBarButtonItems = [backButton] + leftButtons
          }
     }

     /* ################################################################## */
     /**
      Returns to the preceding screen using the navigation controller's normal pop transition.
      */
     @objc private func _goBack() {
          guard navigationController?.topViewController === self,
                nil == navigationController?.transitionCoordinator
          else { return }
          navigationController?.popViewController(animated: true)
     }

     /* ################################################################## */
     /**
      This travels around the whole view hierarchy, and resolves accessibility tokens.
      */
     func accessorizer() {
          /* ############################################################## */
          /**
           This recursively resolves the accessibility tokens for the given view, and its subviews.
           
           - parameter me: The view to "accessorize."
           */
          func accessorize(me inView: UIView) {
               inView.subviews.forEach { accessorize(me: $0) }
               inView.accessibilityLabel = inView.accessibilityLabel?.localizedVariant
               inView.accessibilityHint = inView.accessibilityHint?.localizedVariant
          }
          
          if let tabBar = tabBarController?.tabBar {
               accessorize(me: tabBar)
          }
          
          navigationItem.rightBarButtonItems?.forEach {
               if let view = $0.customView {
                    accessorize(me: view)
               }
               $0.accessibilityLabel = $0.accessibilityLabel?.localizedVariant
               $0.accessibilityHint = $0.accessibilityHint?.localizedVariant
          }
          
          navigationItem.leftBarButtonItems?.forEach {
               if let view = $0.customView {
                    accessorize(me: view)
               }
               $0.accessibilityLabel = $0.accessibilityLabel?.localizedVariant
               $0.accessibilityHint = $0.accessibilityHint?.localizedVariant
          }
          
          navigationItem.centerItemGroups.forEach { item in
               item.barButtonItems.forEach {
                    if let view = $0.customView {
                         accessorize(me: view)
                    }
                    $0.accessibilityLabel = $0.accessibilityLabel?.localizedVariant
                    $0.accessibilityHint = $0.accessibilityHint?.localizedVariant
               }
               item.accessibilityLabel = item.accessibilityLabel?.localizedVariant
               item.accessibilityHint = item.accessibilityHint?.localizedVariant
          }
          
          guard let view = view else { return }
          accessorize(me: view)
     }
     
     /* ################################################################## */
     /**
      Triggers a subtle selection haptic.
      */
     func selectionHaptic() {
          selectionGenerator?.selectionChanged()
          selectionGenerator?.prepare()
     }
     
     /* ################################################################## */
     /**
      Triggers a "success" haptic.
      */
     func successHaptic() {
          notificationGenerator?.notificationOccurred(.success)
          notificationGenerator?.prepare()
     }
     
     /* ################################################################## */
     /**
      Triggers a "soft impact" haptic.
      */
     func softImpactHaptic() {
          feedbackGenerator?.impactOccurred(intensity: 0.25)
          feedbackGenerator?.prepare()
     }
     
     /* ################################################################## */
     /**
      Triggers a "hard impact" haptic.
      */
     func hardImpactHaptic() {
          feedbackGenerator?.impactOccurred(intensity: 1)
          feedbackGenerator?.prepare()
     }
}
