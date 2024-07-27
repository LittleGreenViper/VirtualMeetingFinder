/*
 © Copyright 2024, Little Green Viper Software Development LLC
 LICENSE:
 
 MIT License
 
 Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentationmap
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

/* ###################################################################################################################################### */
// MARK: - Search View Controller -
/* ###################################################################################################################################### */
/**
 This is the main view controller for the weekday/time selector tab.
 
 # QUICK OVERVIEW
 
 The way that the data is set up, we have "day indexes (1-7), and "time slots" (varies, per day).
 
 All times are mapped to the user's local timezone, regardless of the start time in the meeting's "native" timezone.
 
 The instance of this class will have a ``VMF_DayTimeSearchPageViewController`` embedded (also the ``VMF_AttendanceViewController`` class, but that one disables the page view controller), which allows the user to swipe-select pages of meetings.
 
 ## DAY INDEXES
 
 These represent 0 (In Progress), 1 (Sunday), through 7 (Saturday), or 8 (Search Mode).
 
 ### Mode 0 (In Progress)
 
 In this mode, there is no "time index," and the screen displays all meetings that are in progress, regardless of when they started.

 ### Mode 1 -> 7
 
 If the day index is 1 -> 7, the screen displays whatever time index, within that day, is selected.
 
 The day index is stored in Sunday -> Saturday (the database native scheme), but are mapped to the local week, upon display.
 
 ### Mode 8 (Search)
 
 In this mode, the day index and time index are irrelevant. All possible meetings are displayed, then are filtered, "live," as text is entered into the text entry field.
 
 ## TIME INDEXES
 
 Each day has "time slots." These are groupings of times, where meetings start (1 or more). Each "time slot" is a separate group of meetings that all begin at the same time.
 
 In regular weekdays (day index 1 -> 7), only one "time slot" is shown at a time. Only the meetings that begin at the same time are shown.
 
 If possible, the user's currently selected time index is honored, and we try to match the time, when changing selected days. It is also preserved, when entering Mode 0 or Mode 8.
 
 ## SELECTING FOR ATTENDANCE
 
 It is possible for a user to indicate that they attend a meeting, by double-tapping on a meeting in the list, or by selecting "I Attend," in the meeting inspector screen.
 
 You can bring in a separate screen, that contains only the meetings that you attend. This is accessed from the chackmark bar button item, in the upper right.
 */
class VMF_MainViewController: VMF_BaseViewController, VMF_MasterTableControllerProtocol {
    /* ################################################################## */
    /**
     The segue ID of our open attendance.
     */
    static let openAttendanceSegueID = "open-attendance"
    
    /* ################################################################## */
    /**
     The image that we use for search mode.
     */
    static let searchImage = UIImage(systemName: "magnifyingglass")

    /* ################################################################## */
    /**
     The image to use, when attendance is selected.
     */
    static let checkedImage = UIImage(systemName: "checkmark.square.fill")

    /* ################################################################## */
    /**
     The image to use, when we do not attend.
     */
    static let uncheckedImage = UIImage(systemName: "square")
    
    /* ################################################################## */
    /**
     The color of the "mercury" in our "thermometer."
     */
    static let mercuryColor = UIColor.systemRed

    /* ################################################################## */
    /**
     The font for the "I Attend" button.
     */
    static let barButtonLabelFont = UIFont.systemFont(ofSize: 15)
    
    /* ################################################################## */
    /**
     The width of each of the components of our direct picker view.
     */
    static let pickerViewComponentWidthInDisplayUnits = CGFloat(140)

    /* ################################################################## */
    /**
     The container view needs to be wider than this, to show short (as opposed to "very" short) weekdays.
     */
    static let shortWidthThreshold = CGFloat(500)

    /* ################################################################## */
    /**
     The container view needs to be wider than this, to show full (as opposed to short) weekdays.
     */
    static let fullWidthThreshold = CGFloat(1000)

    /* ################################################################## */
    /**
     This is used to restore the bottom of the stack view, when the keyboard is hidden.
     */
    var atRestConstant = CGFloat(0)

    /* ################################################################## */
    /**
     This is used during the long-press slide. It holds the previous location of the gesture.
     We use it to determine if the finger has moved.
     */
    var oldLocation = CGFloat(0)

    /* ################################################################## */
    /**
     This holds the last time of the selected page. We use this to set the time, when directly navigating away from Now.
     */
    var lastTime = Int(0)
    
    /* ################################################################## */
    /**
     This tracks the current embedded table controller.
     */
    var tableDisplayController: VMF_EmbeddedTableControllerProtocol?

    /* ################################################################## */
    /**
     This is our page view controller.
     */
    weak var pageViewController: VMF_DayTimeSearchPageViewController?
    
    /* ################################################################## */
    /**
     This is set to true, if we were (past tense) in name search mode.
     */
    var wasNameSearchMode: Bool = false
    
    /* ################################################################## */
    /**
     Storage for our search meeting source
     */
    var searchMeetings: [MeetingInstance] = []
    
    /* ################################################################## */
    /**
     This has the "mostly organized" meeting data.
     
     The meetings are organized in ascending local time, arranged by weekday, with [0] being Sunday.
     */
    var organizedMeetings: [[MeetingInstance]] = []

    /* ################################################################## */
    /**
     This is set to true, if we are in name search mode.
     */
    var isNameSearchMode: Bool = false {
        didSet {
            searchItemsContainerView?.isHidden = !isNameSearchMode
            weekdayModeSelectorSegmentedSwitch?.isHidden = isNameSearchMode
            if let dayIndex = tableDisplayController?.dayIndex,
               let timeIndex = tableDisplayController?.timeIndex {
                if isNameSearchMode {
                    if !wasNameSearchMode {
                        guard let newViewController = self.getTableDisplay(for: dayIndex, time: timeIndex) else { return }
                        pageViewController?.setViewControllers([newViewController], direction: .forward, animated: false)
                    }
                    wasNameSearchMode = false
                    searchTextField?.becomeFirstResponder()
                    searchTextField?.addTarget(self, action: #selector(searchTextChanged), for: .editingChanged)
                    timeSelectorContainerView?.isHidden = true
                    directSelectionItemsContainer?.isHidden = true
                } else {
                    // The reason for this, is an internal cache reset: https://stackoverflow.com/a/25016836/879365
                    pageViewController?.dataSource = nil
                    pageViewController?.dataSource = self
                    searchTextField?.removeTarget(self, action: #selector(searchTextChanged), for: .editingChanged)
                    searchTextField?.resignFirstResponder()
                    if oldValue != isNameSearchMode {
                        weekdayModeSelectorSegmentedSwitch?.selectedSegmentIndex = mapWeekday(dayIndex)
                        tableDisplayController?.meetings = getCurentMeetings(for: dayIndex, time: timeIndex)
                    }
                    
                    if let ctrl = tableDisplayController as? VMF_EmbeddedTableController {
                        updateThermometer(ctrl)
                        timeDayDisplayLabel?.text = ctrl.title
                    }
                    
                    timeSelectorContainerView?.isHidden = false
                }
                
                tableDisplayController?.meetings = getCurentMeetings(for: dayIndex, time: timeIndex)
            }
            
            if isNameSearchMode != oldValue {
                successHaptic()
            }
            
            (tableDisplayController as? VMF_EmbeddedTableController)?.noRefresh = isNameSearchMode
        }
    }
    
    /* ################################################################## */
    /**
     True, if this is the direct weekday/time selection mode (PickerView displayed).
     */
    var isDirectSelectionMode: Bool = false {
        didSet {
            successHaptic()
            
            if isDirectSelectionMode {
                isNameSearchMode = false
                completionBar?.isHidden = true
                weekdayModeSelectorSegmentedSwitch?.isHidden = true
                timeSelectorContainerView?.isHidden = true
                directSelectionItemsContainer?.isHidden = false
                directSelectionPickerView?.reloadAllComponents()
                (tableDisplayController as? VMF_EmbeddedTableController)?.noRefresh = true  // Disables pull to refresh.
                setDayPicker()
            } else {
                directSelectionItemsContainer?.isHidden = true
                completionBar?.isHidden = false
                weekdayModeSelectorSegmentedSwitch?.isHidden = false
                timeSelectorContainerView?.isHidden = false
                (tableDisplayController as? VMF_EmbeddedTableController)?.noRefresh = false  // Re-enable pull to refresh.
            }
        }
    }
    
    /* ################################################################## */
    /**
     Contains the search text filter. Only relevant, if in Name Search Mode.
     */
    var searchText: String = "" {
        didSet {
            if isNameSearchMode {
                if searchText.isEmpty {
                    tableDisplayController?.meetings = searchMeetings
                } else {
                    tableDisplayController?.meetings = getCurentMeetings()
                }
            }
        }
    }

    /* ################################################################## */
    /**
     This is set to true, if the "throbber" is shown (hiding everything else).
     */
    var isThrobbing: Bool = false {
        didSet {
            isDirectSelectionMode = false
            if isThrobbing {
                navigationController?.isNavigationBarHidden = true
                directSelectionItemsContainer?.isHidden = true
                tableContainerView?.isHidden = true
                completionBar?.isHidden = true
                searchItemsContainerView?.isHidden = true
                weekdayModeSelectorSegmentedSwitch?.isHidden = true
                timeSelectorContainerView?.isHidden = true
                tabBarController?.tabBar.isHidden = true
                throbber?.isHidden = false
            } else {
                throbber?.isHidden = true
                myAttendanceBarButtonItem?.isEnabled = !(VMF_AppDelegate.virtualService?.meetingsThatIAttend.isEmpty ?? true)
                tabBarController?.tabBar.isHidden = false
                searchItemsContainerView?.isHidden = !isNameSearchMode
                weekdayModeSelectorSegmentedSwitch?.isHidden = isNameSearchMode
                timeSelectorContainerView?.isHidden = isNameSearchMode
                completionBar?.isHidden = false
                tableContainerView?.isHidden = false
                navigationController?.isNavigationBarHidden = false
            }
        }
    }

    /* ################################################################## */
    /**
     The bar button item that brings in the Settings Screen.
     */
    @IBOutlet weak var settingsBarButtonItem: UIBarButtonItem?
    
    /* ################################################################## */
    /**
     The bar button item that brings in the My Attendance Screen.
     */
    @IBOutlet weak var myAttendanceBarButtonItem: UIBarButtonItem?
    
    /* ################################################################## */
    /**
     The segmented switch that controls the mode.
     */
    @IBOutlet weak var weekdayModeSelectorSegmentedSwitch: UISegmentedControl?
    
    /* ################################################################## */
    /**
     The embedded table controller container view. This hosts an instance of ``VMF_DayTimeSearchPageViewController``.
     */
    @IBOutlet weak var tableContainerView: UIView?
    
    /* ################################################################## */
    /**
     This contains the search items.
     */
    @IBOutlet weak var searchItemsContainerView: UIStackView?
    
    /* ################################################################## */
    /**
     The text field for entering a search.
     */
    @IBOutlet weak var searchTextField: UITextField?
    
    /* ################################################################## */
    /**
     The button to close the search mode.
     */
    @IBOutlet weak var searchCloseButton: UIButton?

    /* ################################################################## */
    /**
     This contains the time selector items.
     */
    @IBOutlet weak var timeSelectorContainerView: UIView?
    
    /* ################################################################## */
    /**
     The decrement time button
     */
    @IBOutlet weak var leftButton: VMF_TapHoldButton?
    
    /* ################################################################## */
    /**
     The increment time button
     */
    @IBOutlet weak var rightButton: VMF_TapHoldButton?
    
    /* ################################################################## */
    /**
     This displays the current time and day.
     */
    @IBOutlet weak var timeDayDisplayLabel: UILabel?
    
    /* ################################################################## */
    /**
     The bottom constraint of the table display area. We use this to shrink the table area, when the keyboard is shown.
     */
    @IBOutlet weak var bottomConstraint: NSLayoutConstraint?

    /* ################################################################## */
    /**
     This is a narrow bar, along the top, that shows how far into the day we are.
     */
    @IBOutlet weak var completionBar: UIView?
    
    /* ################################################################## */
    /**
     The "Throbber" view
     */
    @IBOutlet weak var throbber: UIView?

    /* ################################################################## */
    /**
     The double-tap gesture for bring us back to today.
     */
    @IBOutlet weak var labelDoubleTapGesture: UITapGestureRecognizer?

    /* ################################################################## */
    /**
     The long-press gesture for selecting a weekday.
     */
    @IBOutlet weak var weekdayLongPressGesture: UILongPressGestureRecognizer?

    /* ################################################################## */
    /**
     The long-press gesture for selecting a time.
     */
    @IBOutlet weak var timeDayLongPressGesture: UILongPressGestureRecognizer?

    /* ################################################################## */
    /**
     The tap recognizer for entering direct selection mode.
     */
    @IBOutlet weak var directSelectionTapRecognizer: UITapGestureRecognizer?
    
    /* ################################################################## */
    /**
     The container, for the Direct Selection Mode items.
     */
    @IBOutlet weak var directSelectionItemsContainer: UIView?
    
    /* ################################################################## */
    /**
     The picker view, for the Direct Selection Mode.
     */
    @IBOutlet weak var directSelectionPickerView: UIPickerView?

    /* ################################################################## */
    /**
     The button to exit Direct Selection Mode.
     */
    @IBOutlet weak var directSelectionCloseButton: UIButton?
}

/* ###################################################################################################################################### */
// MARK: Computed Properties
/* ###################################################################################################################################### */
extension VMF_MainViewController {
    /* ################################################################## */
    /**
     These are the meetings that are currently in progress. They are sorted in ascending local start time.
     */
    var inProgressMeetings: [MeetingInstance] {
        VMF_AppDelegate.virtualService?.meetings.compactMap { $0.isInProgress ? $0.meeting : nil }.sorted { a, b in
            var mutableA = a
            var mutableB = b
            
            let aDate = mutableA.getPreviousStartDate(isAdjusted: true)
            let bDate = mutableB.getPreviousStartDate(isAdjusted: true)
            
            if aDate < bDate {
                return true
            } else if aDate > bDate {
                return false
            } else if a.timeZone.secondsFromGMT() < b.timeZone.secondsFromGMT() {
                return true
            } else if a.timeZone.secondsFromGMT() > b.timeZone.secondsFromGMT() {
                return false
            } else {
                return a.name.lowercased() < b.name.lowercased()
            }
        } ?? []
    }

    /* ################################################################## */
    /**
     Returns now, in terms understood by the meeting search.
     
     weekday is the current weekday, transformed to the meeting data (1 is Sunday)
     currentIntegerTime is the current time, as an integer (hours * 100 + minute).
     */
    var nowIs: (weekday: Int, currentIntegerTime: Int) {
        let day = Calendar.current.component(.weekday, from: .now)
        let hour = Calendar.current.component(.hour, from: .now)
        let minute = Calendar.current.component(.minute, from: .now)
        
        guard (1..<8).contains(day) else { return (weekday: 0, currentIntegerTime: 0) }
        
        return (weekday: day, currentIntegerTime: hour * 100 + minute)
    }
    
    /* ################################################################## */
    /**
     Returns true, if we need to force a reload from the server.
     */
    var needsReload: Bool {
        return nil == VMF_AppDelegate.virtualService
               || (VMF_AppDelegate.virtualService?.meetings.isEmpty ?? true)
               || (VMF_SceneDelegate.forceReloadDelayInSeconds < -VMF_SceneDelegate.lastReloadTime.timeIntervalSinceNow)
    }
}
