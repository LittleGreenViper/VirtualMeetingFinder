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
 */
class VMF_BaseViewController: UIViewController { }

/* ###################################################################################################################################### */
// MARK: Computed Properties
/* ###################################################################################################################################### */
extension VMF_BaseViewController {
    var myTabController: VMF_TabBarController? { tabBarController as? VMF_TabBarController }
}

/* ###################################################################################################################################### */
// MARK: Instance Methods
/* ###################################################################################################################################### */
extension VMF_BaseViewController {
    /* ################################################################## */
    /**
     This converts a 1 == Sun format into a localized weekday index (1 ... 7)
     
     - parameter: An integer (1 = Sunday), with the unlocalized index.
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
     
     - parameter: An integer (1 -> 7), with the localized weekday.
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
     Called just before the view is to appear.
     
     - parameter inIsAnimated: True, if the appearance is animated.
     */
    override func viewWillAppear(_ inIsAnimated: Bool) {
        super.viewWillAppear(inIsAnimated)
        navigationItem.title = navigationItem.title?.localizedVariant
    }
}

/* ###################################################################################################################################### */
// MARK: - Base View Controller for Tab Roots -
/* ###################################################################################################################################### */
/**
 This class should be used as the base class for the "root" view controller for each tab.
 */
class VMF_TabBaseViewController: VMF_BaseViewController { }

/* ###################################################################################################################################### */
// MARK: Base Class Overrides
/* ###################################################################################################################################### */
extension VMF_TabBaseViewController {
    /* ################################################################## */
    /**
     Called after the resources have been loaded and resolved.
     */
    override func viewDidLoad() {
        super.viewDidLoad()
    }
}

/* ###################################################################################################################################### */
// MARK: - Custom Tab Bar Controller -
/* ###################################################################################################################################### */
/**
 */
class VMF_TabBarController: UITabBarController { }

/* ###################################################################################################################################### */
// MARK: Base Class Overrides
/* ###################################################################################################################################### */
extension VMF_TabBarController {
    /* ################################################################## */
    /**
     Called after the resources have been loaded and resolved.
     */
    override func viewDidLoad() {
        super.viewDidLoad()
        delegate = self
        tabBar.items?.forEach { $0.title = $0.title?.localizedVariant }
    }
    
    /* ################################################################## */
    /**
     Called just before the view is to appear.
     
     - parameter inIsAnimated: True, if the appearance is animated.
     */
    override func viewWillAppear(_ inIsAnimated: Bool) {
        super.viewWillAppear(inIsAnimated)
        navigationItem.title = selectedViewController?.navigationItem.title
        navigationController?.isNavigationBarHidden = true
        navigationController?.isNavigationBarHidden = false
        checkAttendance()
    }
}

/* ###################################################################################################################################### */
// MARK: Instance Methods
/* ###################################################################################################################################### */
extension VMF_TabBarController {
    /* ################################################################## */
    /**
     Enables or disables the attendance tab, if no meetings are marked for attendance.
     */
    func checkAttendance() {
        guard let count = tabBar.items?.count,
              1 < count
        else { return }
        
        tabBar.items?[1].isEnabled = !(VMF_AppDelegate.virtualService?.meetingsThatIAttend.isEmpty ?? true)
    }
}

/* ###################################################################################################################################### */
// MARK: UITabBarControllerDelegate Conformance
/* ###################################################################################################################################### */
extension VMF_TabBarController: UITabBarControllerDelegate {
    /* ################################################################## */
    /**
     */
    func tabBarController(_: UITabBarController, didSelect inNewViewController: UIViewController) {
        if let destination = inNewViewController as? VMF_AttendanceViewController {
            destination.tableDisplayController?.meetings = destination.meetings
        }
    }
}
