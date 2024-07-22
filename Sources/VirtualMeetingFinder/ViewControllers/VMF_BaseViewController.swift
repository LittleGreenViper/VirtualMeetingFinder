/*
 © Copyright 2024, Little Green Viper Software Development LLC
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
 The base class for all our view controllers.
 */
class VMF_BaseViewController: UIViewController {
    /* ################################################################## */
    /**
     Keeps track of our gradient layer.
     */
    private weak var _backgroundGradientLayer: CALayer?
    
    /* ################################################################## */
    /**
     This will provide haptic/audio feedback, in general.
     */
    var feedbackGenerator: UIImpactFeedbackGenerator?

    /* ################################################################## */
    /**
     This will provide haptic/audio feedback, in general.
     */
    var notificationGenerator: UINotificationFeedbackGenerator?

    /* ################################################################## */
    /**
     This will provide subtle haptic/audio feedback for selections.
     */
    var selectionGenerator: UISelectionFeedbackGenerator?
}

/* ###################################################################################################################################### */
// MARK: Computed Properties
/* ###################################################################################################################################### */
extension VMF_BaseViewController {
    /* ################################################################## */
    /**
     Convenient prefs instance.
     */
    var prefs: VMF_Prefs {
        get { VMF_AppDelegate.prefs }
        set { VMF_AppDelegate.prefs = newValue }
    }
}

/* ###################################################################################################################################### */
// MARK: Instance Methods
/* ###################################################################################################################################### */
extension VMF_BaseViewController {
    /* ################################################################## */
    /**
     This converts a 1 == Sun format into a localized weekday index (1 ... 7)
     
     - parameter: An integer (1 -> 7), with the unlocalized index (database native setup).
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
     
     - parameter: An integer (1 -> 7), with the localized weekday (user's native setup).
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
        var ret = ""
        
        var meeting = inMeeting
        let nativeTime = meeting.getNextStartDate(isAdjusted: false)
        
        if let myCurrentTimezoneName = TimeZone.current.localizedName(for: .standard, locale: .current),
           let zoneName = meeting.timeZone.localizedName(for: .standard, locale: .current),
           !zoneName.isEmpty,
           myCurrentTimezoneName != zoneName {
            ret = String(format: "SLUG-TIMEZONE-FORMAT".localizedVariant, zoneName, nativeTime.localizedTime)
        }
        
        return ret
    }
}

/* ###################################################################################################################################### */
// MARK: Base Class Overrides
/* ###################################################################################################################################### */
extension VMF_BaseViewController {
    /* ################################################################## */
    /**
     Called when the view hierarchy is complete.
     We use this to prep our haptics.
     */
    override func viewDidLoad() {
        super.viewDidLoad()
        navigationController?.isToolbarHidden = true
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
        accessorizer()
        _backgroundGradientLayer?.removeFromSuperlayer()
        
        guard let view = view,
              let startColor = UIColor(named: "Background-Begin")?.cgColor,
              let endColor = UIColor(named: "Background-End")?.cgColor
        else { return }

        let gradientLayer = CAGradientLayer()
        gradientLayer.colors = [startColor, endColor]
        gradientLayer.startPoint = CGPoint(x: 0.5, y: 0.0)
        gradientLayer.endPoint = CGPoint(x: 0.5, y: 1.0)
        gradientLayer.locations = [0, 1]
        gradientLayer.frame = view.bounds

        view.layer.insertSublayer(gradientLayer, at: 0)
        _backgroundGradientLayer = gradientLayer
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
}

/* ###################################################################################################################################### */
// MARK: Instance Methods
/* ###################################################################################################################################### */
extension VMF_BaseViewController {
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
            inView.accessibilityLabel = inView.accessibilityLabel?.accessibilityLocalizedVariant
            inView.accessibilityHint = inView.accessibilityHint?.accessibilityLocalizedVariant
        }
        
        if let tabBar = tabBarController?.tabBar {
            accessorize(me: tabBar)
        }
        
        navigationItem.rightBarButtonItems?.forEach {
            if let view = $0.customView {
                accessorize(me: view)
            }
            $0.accessibilityLabel = $0.accessibilityLabel?.accessibilityLocalizedVariant
            $0.accessibilityHint = $0.accessibilityHint?.accessibilityLocalizedVariant
        }
        
        navigationItem.leftBarButtonItems?.forEach {
            if let view = $0.customView {
                accessorize(me: view)
            }
            $0.accessibilityLabel = $0.accessibilityLabel?.accessibilityLocalizedVariant
            $0.accessibilityHint = $0.accessibilityHint?.accessibilityLocalizedVariant
        }
        
        navigationItem.centerItemGroups.forEach { item in
            item.barButtonItems.forEach {
                if let view = $0.customView {
                    accessorize(me: view)
                }
                $0.accessibilityLabel = $0.accessibilityLabel?.accessibilityLocalizedVariant
                $0.accessibilityHint = $0.accessibilityHint?.accessibilityLocalizedVariant
            }
            item.accessibilityLabel = item.accessibilityLabel?.accessibilityLocalizedVariant
            item.accessibilityHint = item.accessibilityHint?.accessibilityLocalizedVariant
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
