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
import RVS_BasicGCDTimer

/* ###################################################################################################################################### */
// MARK: - Special Button for "Tap and Hold" -
/* ###################################################################################################################################### */
/**
 This allows single taps, or hold to repeat (like steppers).
 */
class TapHoldButton: UIControl {
    /* ################################################################## */
    /**
     The gesture recognizer for single taps.
     */
    private weak var _tapGestureRecognizer: UITapGestureRecognizer?
    
    /* ################################################################## */
    /**
     The gesture recognizer for long-press repeat.
     */
    private weak var _longHoldGestureRecognizer: UILongPressGestureRecognizer?
    
    /* ################################################################## */
    /**
     This manages the repeated calls.
     */
    private var _repeater: RVS_BasicGCDTimer?
    
    /* ################################################################## */
    /**
     The view that contains the button image.
     */
    private weak var _displayImageView: UIImageView?

    /* ################################################################## */
    /**
     This is how often we repeat, when long-pressing.
     */
    @IBInspectable var repeatFrequencyInSeconds = TimeInterval(0.15)
    
    /* ################################################################## */
    /**
     */
    @IBInspectable var displayImage: UIImage? { didSet { setNeedsLayout() } }
}

/* ###################################################################################################################################### */
// MARK: Callbacks
/* ###################################################################################################################################### */
extension TapHoldButton {
    /* ################################################################## */
    /**
     Called for a single tap
     
     - parameter: The recognizer (ignored).
     */
    @objc func tapGesture(_: UITapGestureRecognizer) {
        sendActions(for: .primaryActionTriggered)
    }
    
    /* ################################################################## */
    /**
     Called for a long-press. The action will be repeated at a regular interval.
     
     - parameter inGesture: The gesture recognizer instance.
     */
    @objc func longPressGesture(_ inGesture: UILongPressGestureRecognizer) {
        switch inGesture.state {
        case .began:
            _repeater = RVS_BasicGCDTimer(timeIntervalInSeconds: repeatFrequencyInSeconds, onlyFireOnce: false, queue: .main) { _, _ in self.sendActions(for: .primaryActionTriggered) }
            _repeater?.resume()
            
        case .ended, .cancelled:
            _repeater?.invalidate()
            _repeater = nil
            
        default:
            break
        }
    }
}

/* ###################################################################################################################################### */
// MARK: Base Class Overrides
/* ###################################################################################################################################### */
extension TapHoldButton {
    /* ################################################################## */
    /**
     Called when the views are laid out.
     
     We use this to initialize the object.
     */
    override func layoutSubviews() {
        super.layoutSubviews()
        
        _displayImageView?.removeFromSuperview()
        
        if let displayImage = displayImage {
            let tempView = UIImageView(image: displayImage)
            tempView.contentMode = .scaleAspectFit
            addSubview(tempView)
            _displayImageView = tempView
            tempView.translatesAutoresizingMaskIntoConstraints = false
            tempView.topAnchor.constraint(equalTo: topAnchor, constant: 4).isActive = true
            tempView.leftAnchor.constraint(equalTo: leftAnchor, constant: 4).isActive = true
            tempView.bottomAnchor.constraint(equalTo: bottomAnchor, constant: 4).isActive = true
            tempView.rightAnchor.constraint(equalTo: rightAnchor, constant: 4).isActive = true
        }
        
        if nil == _longHoldGestureRecognizer {
            let tempGesture = UILongPressGestureRecognizer(target: self, action: #selector(longPressGesture))
            addGestureRecognizer(tempGesture)
            _longHoldGestureRecognizer = tempGesture
        }

        if nil == _tapGestureRecognizer,
           let lp = _longHoldGestureRecognizer {
            let tempGesture = UITapGestureRecognizer(target: self, action: #selector(tapGesture))
            tempGesture.require(toFail: lp)
            addGestureRecognizer(tempGesture)
            _tapGestureRecognizer = tempGesture
        }
    }
}

/* ###################################################################################################################################### */
// MARK: - Search View Controller -
/* ###################################################################################################################################### */
/**
 This is the main view controller for the weekday/time selector tab.
 */
class VMF_DayTimeSearchViewController: VMF_TabBaseViewController, VMF_MasterTableControllerProtocol {
    /* ################################################################## */
    /**
     The image that we use for search mode.
     */
    private static let _searchImage = UIImage(systemName: "magnifyingglass")
    
    /* ################################################################## */
    /**
     The color of the "mercury" in our "thermometer."
     */
    private static let _mercuryColor = UIColor.systemRed
    
    /* ################################################################## */
    /**
     This is used to restore the bottom of the stack view, when the keyboard is hidden.
     */
    private var _atRestConstant: CGFloat = 0
    
    /* ################################################################## */
    /**
     This holds the last time of the selected page. We use this to set the time, when directly navigating away from Now.
     */
    private var _lastTime: Int = 0
    
    /* ################################################################## */
    /**
     This handles the server data.
     */
    weak var virtualService: SwiftBMLSDK_MeetingLocalTimezoneCollection?
    
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
     This is set to true, if we are in name search mode.
     */
    var isNameSearchMode: Bool = false {
        didSet {
            searchItemsContainerView?.isHidden = !isNameSearchMode
            weekdayModeSelectorSegmentedSwitch?.isHidden = isNameSearchMode
            if let dayIndex = tableDisplayController?.dayIndex,
               let timeIndex = tableDisplayController?.timeIndex {
                if isNameSearchMode {
                    guard let newViewController = self.getTableDisplay(for: dayIndex, time: timeIndex) else { return }
                    pageViewController?.setViewControllers([newViewController], direction: .forward, animated: false)
                    searchTextField?.becomeFirstResponder()
                    timeSelectorContainerView?.isHidden = true
                } else {
                    searchTextField?.resignFirstResponder()
                    if oldValue != isNameSearchMode {
                        weekdayModeSelectorSegmentedSwitch?.selectedSegmentIndex = mapWeekday(dayIndex)
                        tableDisplayController?.meetings = getCurentMeetings(for: dayIndex, time: timeIndex)
                    }
                    timeDayDisplayLabel?.text = (tableDisplayController as? UIViewController)?.title
                    timeSelectorContainerView?.isHidden = false
                }
                
                tableDisplayController?.meetings = getCurentMeetings(for: dayIndex, time: timeIndex)
            }
            
            (tableDisplayController as? VMF_EmbeddedTableController)?.noRefresh = isNameSearchMode
        }
    }
    
    /* ################################################################## */
    /**
     Contains the search text filter.
     */
    var searchText: String = "" {
        didSet {
            if isNameSearchMode {
                if searchText.isEmpty {
                    tableDisplayController?.meetings = searchMeetings
                } else {
                    let searchM = getCurentMeetings()
                    tableDisplayController?.meetings = searchM
                }
            }
        }
    }
    
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
     This is set to true, if the "throbber" is shown (hiding everything else).
     */
    var isThrobbing: Bool = false {
        didSet {
            if isThrobbing {
                navigationController?.isNavigationBarHidden = true
                tableContainerView?.isHidden = true
                searchItemsContainerView?.isHidden = true
                weekdayModeSelectorSegmentedSwitch?.isHidden = true
                timeSelectorContainerView?.isHidden = true
                tabBarController?.tabBar.isHidden = true
                throbber?.isHidden = false
            } else {
                throbber?.isHidden = true
                tabBarController?.tabBar.isHidden = false
                myTabController?.checkAttendance()
                searchItemsContainerView?.isHidden = !isNameSearchMode
                weekdayModeSelectorSegmentedSwitch?.isHidden = isNameSearchMode
                timeSelectorContainerView?.isHidden = isNameSearchMode
                tableContainerView?.isHidden = false
                navigationController?.isNavigationBarHidden = false
            }
        }
    }

    /* ################################################################## */
    /**
     The segmented switch that controls the mode.
     */
    @IBOutlet weak var weekdayModeSelectorSegmentedSwitch: UISegmentedControl?
    
    /* ################################################################## */
    /**
     The embedded table controller container view.
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
    @IBOutlet weak var leftButton: TapHoldButton?
    
    /* ################################################################## */
    /**
     The increment time button
     */
    @IBOutlet weak var rightButton: TapHoldButton?
    
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
}

/* ###################################################################################################################################### */
// MARK: Computed Properties
/* ###################################################################################################################################### */
extension VMF_DayTimeSearchViewController {
    /* ################################################################## */
    /**
     These are the meetings that are currently in progress. They are sorted in ascending local start time.
     */
    var inProgressMeetings: [MeetingInstance] {
        self.virtualService?.meetings.compactMap { $0.isInProgress ? $0.meeting : nil }.sorted { a, b in
            var mutableA = a
            var mutableB = b
            
            let aDate = mutableA.getPreviousStartDate(isAdjusted: true)
            let bDate = mutableB.getPreviousStartDate(isAdjusted: true)

            if aDate < bDate {
                return true
            } else if aDate > bDate {
                return false
            } else if a.timeZone.identifier < b.timeZone.identifier {
                return true
            } else if a.timeZone.identifier > b.timeZone.identifier {
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
}

/* ###################################################################################################################################### */
// MARK: Instance Methods
/* ###################################################################################################################################### */
extension VMF_DayTimeSearchViewController {
    /* ################################################################## */
    /**
     Called to load the meetings from the server.
     
     - parameter completion: A simple, no-parameter completion. It is always called in the main thread.
     */
    func loadMeetings(completion inCompletion: @escaping () -> Void) {
        isThrobbing = true
        virtualService = nil
        searchMeetings = []
        organizedMeetings = []
        
        VMF_AppDelegate.findMeetings { [weak self] inVirtualService in
            VMF_SceneDelegate.lastReloadTime = .now
            
            self?.virtualService = inVirtualService
            
            self?.searchMeetings = inVirtualService?.meetings.map { $0.meeting }.sorted { a, b in
                let aLower = a.name.lowercased()
                let bLower = b.name.lowercased()
                
                if aLower < bLower {
                    return true
                } else if aLower > bLower {
                    return false
                } else if a.timeZone.identifier < b.timeZone.identifier {
                    return true
                } else if a.timeZone.identifier > b.timeZone.identifier {
                    return false
                } else {
                    return a.adjustedIntegerStartTime < b.adjustedIntegerStartTime
                }
            } ?? []
            
            for index in 1..<8 {
                self?.organizedMeetings.append(self?.searchMeetings.compactMap { index == $0.adjustedWeekday ? $0 : nil }.sorted { a, b in
                    if a.adjustedIntegerStartTime < b.adjustedIntegerStartTime {
                        return true
                    } else if a.adjustedIntegerStartTime < b.adjustedIntegerStartTime {
                        return false
                    } else if a.timeZone.identifier < b.timeZone.identifier {
                        return true
                    } else if a.timeZone.identifier > b.timeZone.identifier {
                        return false
                    } else {
                        return a.name.lowercased() < b.name.lowercased()
                    }
                } ?? [])
            }
            
            DispatchQueue.main.async {
                self?.isThrobbing = false
                inCompletion()
            }
        }
    }

    /* ################################################################## */
    /**
     Get the meetings for a particular weekday.
     
     - parameter for: The 1-based (1 is Sunday) weekday index
     - returns: a Dictionary, with the weekday's meetings, organized by localized start time (the key)
     */
    func getDailyMeetings(for inWeekdayIndex: Int) -> [Int: [MeetingInstance]] {
        guard (1..<(organizedMeetings.count + 1)).contains(inWeekdayIndex) else { return [:] }
        
        var ret = [Int: [MeetingInstance]]()
        
        organizedMeetings[inWeekdayIndex - 1].forEach {
            let key = $0.adjustedIntegerStartTime
            if nil == ret[key] {
                ret[key] = [$0]
            } else {
                ret[key]?.append($0)
            }
        }
        
        return ret
    }
    
    /* ################################################################## */
    /**
     This returns a new destination controller to use for transitions.
     
     NOTE: If the controller is in text search mode, then the name search controller is returned.
     
     - parameter for: The 0-based "day index." If it is 0, though, it is the "in-progress" display.
     - parameter time: The 0-based time index. This is the index of the currently selected time slot.
     - returns: A new (or reused) view controller, for the destination of the transition.
     */
    func getTableDisplay(for inDayIndex: Int, time inTimeIndex: Int) -> VMF_EmbeddedTableController? {
        let dayIndex = max(0, min(organizedMeetings.count, inDayIndex))
        
        let dailyMeetings = getDailyMeetings(for: dayIndex)
        let timeIndex = max(0, min(inTimeIndex, dailyMeetings.keys.count - 1))
        let meetings = getCurentMeetings(for: dayIndex, time: timeIndex)

        guard let newViewController = storyboard?.instantiateViewController(withIdentifier: VMF_EmbeddedTableController.storyboardID) as? VMF_EmbeddedTableController else { return nil }
        
        newViewController.myController = self
        newViewController.timeIndex = timeIndex
        newViewController.dayIndex = dayIndex
        newViewController.meetings = meetings
        
        if !isNameSearchMode,
           0 < dayIndex {
            guard (1..<8).contains(dayIndex) else { return nil }
            var testMeeting = meetings.first
            let timeString = testMeeting?.getNextStartDate(isAdjusted: true).localizedTime ?? "ERROR"
            let weekdayString = Calendar.current.weekdaySymbols[dayIndex - 1]
            newViewController.title = String(format: "SLUG-WEEKDAY-TIME-FORMAT".localizedVariant, weekdayString, timeString)
        } else if isNameSearchMode {
            newViewController.title = (tableDisplayController as? UIViewController)?.title
        } else if 0 == dayIndex {
            newViewController.title = "SLUG-IN-PROGRESS".localizedVariant
        }
        
        newViewController.noRefresh = isNameSearchMode

        if (1..<8).contains(dayIndex) {
            _lastTime = getTimeOf(dayIndex: dayIndex, timeIndex: timeIndex) ?? 0
        }
        
        return newViewController
    }
    
    /* ################################################################## */
    /**
     This returns a the meetings we should display, given the day and time.
     
     NOTE: If the controller is in text search mode, then the search set is returned.
     
     - parameter for: The 0-based "day index." If it is 0, though, it is the "in-progress" display.
     - parameter time: The 0-based time index. This is the index of the currently selected time slot.
     - returns: A new (or reused) view controller, for the destination of the transition.
     */
    func getCurentMeetings(for inDayIndex: Int = 0, time inTimeIndex: Int = 0) -> [MeetingInstance] {
        var meetings = [MeetingInstance]()

        if isNameSearchMode {
            if searchText.isEmpty {
                meetings = searchMeetings
            } else {
                meetings = searchMeetings.filter { $0.name.lowercased().contains(searchText.lowercased()) }
            }
        } else if 0 == inDayIndex {
            meetings = inProgressMeetings
        } else {
            let tempMeetings = getDailyMeetings(for: inDayIndex)
            let keys = tempMeetings.keys.sorted()
            let timeIndex = max(0, min(inTimeIndex, keys.count - 1))
            let key = keys[timeIndex]
            meetings = tempMeetings[key] ?? []
        }
        
        return meetings
    }
    
    /* ################################################################## */
    /**
     This opens the screen to a certain day index, and time index.
     
     - parameter dayIndex: The 1-based (but 0 is in progress, 1-7 is Sunday through Saturday) day index. If omitted, then today/now is selected, and time is ignored.
     - parameter time: The military time (HHMM), as an integer. If omitted, 12AM is assumed.
     */
    func openTo(dayIndex inDayIndex: Int = -1, time inMilitaryTime: Int = 0) {
        isNameSearchMode = false
        let weekday = (0..<8).contains(inDayIndex) ? inDayIndex : -1 == inDayIndex ? nowIs.weekday : 0
        let time = (0..<8).contains(inDayIndex) && (0..<2400).contains(inMilitaryTime) ? inMilitaryTime : -1 == inDayIndex ? nowIs.currentIntegerTime : 0
        
        let nextIndex = getNearestIndex(dayIndex: weekday, time: time)
        guard let newViewController = getTableDisplay(for: weekday, time: nextIndex) else { return }
        
        pageViewController?.setViewControllers([newViewController], direction: .forward, animated: false)
        weekdayModeSelectorSegmentedSwitch?.selectedSegmentIndex = mapWeekday(weekday)
        
        timeDayDisplayLabel?.text = newViewController.title
    }
    
    /* ################################################################## */
    /**
     This returns the index, of the time just after (or at) the given time and day.
     
     - parameter dayIndex: The 1-based day index. If omitted, then today/now is selected, and time is ignored.
     - parameter time: The military time (HHMM), as an integer. If omitted, 12AM (0000) is assumed.
     - returns: The index of the next time slot after (or at the same time as) the given time.
     */
    func getNearestIndex(dayIndex inDayIndex: Int = -1, time inMilitaryTime: Int = 0) -> Int {
        let weekday = (1..<8).contains(inDayIndex) ? inDayIndex : -1 == inDayIndex ? nowIs.weekday : 0
        let time = (1..<8).contains(inDayIndex) && (0..<2400).contains(inMilitaryTime) ? inMilitaryTime : -1 == inDayIndex ? nowIs.currentIntegerTime : 0

        let dailyMeetings = getDailyMeetings(for: weekday)
        let dailyKeys = dailyMeetings.keys.sorted()
        var nextIndex = 0
        
        for index in (0..<max(0, dailyKeys.count - 1)) {
            let before = dailyKeys[index]
            let after = dailyKeys[index + 1]
            
            if (before...after).contains(time) {
                nextIndex = (time - before) <= (after - time) ? index : index + 1
                break
            } else if before >= time {
                nextIndex = max(0, index - 1)
                break
            } else if after >= time {
                nextIndex = min(dailyKeys.count - 1, index + 1)
                break
            }
        }
        
        return nextIndex
    }
    
    /* ################################################################## */
    /**
     This returns the time that corresponds to the day and time presented.
     
     - parameter dayIndex: The 1-based day index.
     - parameter timeIndex: The index, as a 0-based integer.
     - returns: The time, as a military time integer, of the time slot for the given time. Returns nil, if the time can't be found.
     */
    func getTimeOf(dayIndex inDayIndex: Int = -1, timeIndex inTimeIndex: Int = 0) -> Int? {
        guard (1..<8).contains(inDayIndex) else { return nil }
        let dailyKeys = getDailyMeetings(for: inDayIndex).keys.sorted()
        guard (0..<dailyKeys.count).contains(inTimeIndex) else { return nil }
        return dailyKeys[inTimeIndex]
    }
    
    /* ################################################################## */
    /**
     This updates the "thermometer" display, in the time selector.
     */
    func updateThermometer(_ inTablePage: VMF_EmbeddedTableControllerProtocol?) {
        guard let tablePage = inTablePage,
              let prevPage = tableDisplayController,
              let completionBar = completionBar,
              let repeatDuration = leftButton?.repeatFrequencyInSeconds,
              !isNameSearchMode
        else {
            completionBar?.isHidden = true
            return
        }
        
        completionBar.isHidden = false
        completionBar.subviews.forEach { $0.removeFromSuperview() }
        
        let dayIndex = tablePage.dayIndex
        let prevTimeIndex = prevPage.timeIndex
        var timeIndex = tablePage.timeIndex

        var dailyMeetings = [Int: [MeetingInstance]]()
        var prevDailyMeetings = [Int: [MeetingInstance]]()

        if 0 == dayIndex {
            return
        } else if 0 < dayIndex,
           0 != prevPage.dayIndex {
            dailyMeetings = getDailyMeetings(for: dayIndex)
        
            guard (0..<dailyMeetings.count).contains(timeIndex)
            else {
                completionBar.isHidden = true
                return
            }
        } else if (1 == dayIndex && 0 == prevPage.dayIndex) || 0 == dayIndex {
            timeIndex = 0
        } else if 7 == dayIndex,
                  0 == prevPage.dayIndex {
            timeIndex = dailyMeetings.count - 1
        }
        
        prevDailyMeetings = getDailyMeetings(for: prevPage.dayIndex)

        let oldWidth = CGFloat(prevTimeIndex + 1) / max(1, CGFloat(prevDailyMeetings.count))
        let newWidth = CGFloat(timeIndex + 1) / max(1, CGFloat(dailyMeetings.count))
        let mercury = UIView()
        mercury.backgroundColor = Self._mercuryColor
        mercury.cornerRadius = completionBar.bounds.size.height / 2
        completionBar.addSubview(mercury)
        mercury.translatesAutoresizingMaskIntoConstraints = false
        mercury.topAnchor.constraint(equalTo: completionBar.topAnchor).isActive = true
        mercury.leftAnchor.constraint(equalTo: completionBar.leftAnchor).isActive = true
        mercury.bottomAnchor.constraint(equalTo: completionBar.bottomAnchor).isActive = true
        mercury.widthAnchor.constraint(equalTo: completionBar.widthAnchor, multiplier: oldWidth).isActive = true
        mercury.layoutIfNeeded()
        UIView.animate(withDuration: repeatDuration) {
            mercury.widthAnchor.constraint(equalTo: completionBar.widthAnchor, multiplier: newWidth).isActive = true
            mercury.layoutIfNeeded()
        }
    }
}

/* ###################################################################################################################################### */
// MARK: Callbacks
/* ###################################################################################################################################### */
extension VMF_DayTimeSearchViewController {
    /* ################################################################## */
    /**
     The segmented switch that controls the mode was hit.
     
     - parameter inSwitch: The segmented switch.
     */
    @IBAction func weekdayModeSelectorSegmentedSwitchHit(_ inSwitch: UISegmentedControl) {
        let selectedIndex = inSwitch.selectedSegmentIndex
        let originalDayIndex = tableDisplayController?.dayIndex ?? 0
        var timeIndex = tableDisplayController?.timeIndex ?? 0
        if selectedIndex == (inSwitch.numberOfSegments - 1) {
            isNameSearchMode = true
            let dayIndex = tableDisplayController?.dayIndex ?? 0
            guard let newViewController = self.getTableDisplay(for: dayIndex, time: timeIndex) else { return }
            self.pageViewController?.setViewControllers([newViewController], direction: .forward, animated: false)
        } else {
            isNameSearchMode = false
            let dayIndex = unMapWeekday(selectedIndex)
            
            if (1..<8).contains(dayIndex),
               0 < _lastTime {
                timeIndex = getNearestIndex(dayIndex: dayIndex, time: _lastTime)
            } else if 0 < originalDayIndex,
               0 < dayIndex,
               0 < timeIndex,
               let originalTime = getTimeOf(dayIndex: originalDayIndex, timeIndex: timeIndex) {
                timeIndex = getNearestIndex(dayIndex: dayIndex, time: originalTime)
            }
            
            guard let newViewController = self.getTableDisplay(for: dayIndex, time: timeIndex) else { return }
            self.pageViewController?.setViewControllers([newViewController], direction: .forward, animated: false)
        }
        
        timeDayDisplayLabel?.text = (tableDisplayController as? UIViewController)?.title
    }
    
    /* ################################################################## */
    /**
     Called when something changes in the search text field.
     */
    @IBAction func searchTextChanged(_ inTextField: UITextField) {
        searchText = inTextField.text ?? ""
    }
    
    /* ################################################################## */
    /**
     Called when the search close button is hit.
     */
    @IBAction func searchCloseHit(_: Any) {
        isNameSearchMode = false
    }
    
    /* ################################################################## */
    /**
     The decrement time button was hit.
     
     - parameter: ignored
     */
    @IBAction func leftButtonHit(_: Any) {
        if !isNameSearchMode,
           var dayIndex = tableDisplayController?.dayIndex,
           var timeIndex = tableDisplayController?.timeIndex {
            timeIndex -= 1

            if 0 == dayIndex || 0 > timeIndex {
                if 0 == dayIndex {
                    dayIndex = unMapWeekday(7)
                    timeIndex = getDailyMeetings(for: dayIndex).keys.count - 1
                } else if unMapWeekday(1) == dayIndex {
                    dayIndex = 0
                    timeIndex += 1
                } else {
                    dayIndex -= 1
                    timeIndex = getDailyMeetings(for: dayIndex).keys.count - 1
                }
            }
            
            guard let newViewController = getTableDisplay(for: dayIndex, time: timeIndex) else { return }
            pageViewController?.setViewControllers([newViewController], direction: .reverse, animated: false)
            timeDayDisplayLabel?.text = (tableDisplayController as? UIViewController)?.title
            weekdayModeSelectorSegmentedSwitch?.selectedSegmentIndex = mapWeekday(dayIndex)
            timeDayDisplayLabel?.text = (tableDisplayController as? UIViewController)?.title
        }
    }
    
    /* ################################################################## */
    /**
     The increment time button was hit.
     
     - parameter: ignored
     */
    @IBAction func rightButtonHit(_: Any) {
        if !isNameSearchMode,
           var dayIndex = tableDisplayController?.dayIndex,
           var timeIndex = tableDisplayController?.timeIndex {
            timeIndex += 1
            if 0 == dayIndex || timeIndex >= getDailyMeetings(for: dayIndex).keys.count {
                if 0 == dayIndex {
                    dayIndex = unMapWeekday(1)
                    timeIndex = 0
                } else if unMapWeekday(7) == dayIndex {
                    dayIndex = 0
                    timeIndex -= 1
                } else {
                    dayIndex += 1
                    timeIndex = 0
                }
            }
            guard let newViewController = getTableDisplay(for: dayIndex, time: timeIndex) else { return }
            pageViewController?.setViewControllers([newViewController], direction: .reverse, animated: false)
            weekdayModeSelectorSegmentedSwitch?.selectedSegmentIndex = mapWeekday(dayIndex)
            timeDayDisplayLabel?.text = (tableDisplayController as? UIViewController)?.title
        }
    }
    
    /* ################################################################## */
    /**
     The long-press gesture recognizer on the weekday switch was triggered.
     
     This resets the screen to today/now.
     
     - parameter: ignored
     */
    @IBAction func longPressOnWeekdayBar(_: Any) {
        if !isNameSearchMode {
            openTo()
        }
    }

    /* ################################################################## */
    /**
     This is called just before the keyboard shows. We use this to "nudge" the table bottom up.
     
     - parameter notification: The notification being passed in.
     */
    @objc func keyboardWillShow(notification inNotification: NSNotification) {
        DispatchQueue.main.async { [weak self] in
            if let keyboardSize = (inNotification.userInfo?[UIResponder.keyboardFrameEndUserInfoKey] as? NSValue)?.cgRectValue {
                let newPosition = (keyboardSize.size.height - (self?.view?.safeAreaInsets.bottom ?? 0))
                self?.bottomConstraint?.constant = newPosition
            }
        }
    }

    /* ################################################################## */
    /**
     This is called just before the keyboard shows. We use this to return the table bottom to its original position.
     
     - parameter notification: The notification being passed in.
     */
    @objc func keyboardWillHide(notification: NSNotification) {
        DispatchQueue.main.async { [weak self] in
            self?.bottomConstraint?.constant = self?._atRestConstant ?? 0
        }
    }
    
    /* ################################################################## */
    /**
     Reloads all the meetings.
     
     - parameter completion: A simple empty callback. Always called in the main thread.
     */
    func refreshCalled(completion inCompletion: @escaping () -> Void) {
        guard !isNameSearchMode else { return }
        loadMeetings(completion: inCompletion)
    }
}

/* ###################################################################################################################################### */
// MARK: Base Class Overrides
/* ###################################################################################################################################### */
extension VMF_DayTimeSearchViewController {
    /* ################################################################## */
    /**
     Called when the view hierarchy loads.
     */
    override func viewDidLoad() {
        super.viewDidLoad()
        navigationItem.title = "SLUG-TAB-0-TITLE".localizedVariant
        VMF_AppDelegate.searchController = self
        searchTextField?.placeholder = searchTextField?.placeholder?.localizedVariant
        _atRestConstant = bottomConstraint?.constant ?? 0
    }
    
    /* ################################################################## */
    /**
     Called just before the view is to appear.
     
     - parameter inIsAnimated: True, if the appearance is animated.
     */
    override func viewWillAppear(_ inIsAnimated: Bool) {
        super.viewWillAppear(inIsAnimated)
        
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(keyboardWillShow),
            name: UIResponder.keyboardWillShowNotification,
            object: nil
        )
        
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(keyboardWillHide),
            name: UIResponder.keyboardWillHideNotification,
            object: nil
        )
        
        view?.setNeedsLayout()
        
        if VMF_SceneDelegate.forceReloadDelayInSeconds < -VMF_SceneDelegate.lastReloadTime.timeIntervalSinceNow {
            loadMeetings { self.openTo() }
        }
    }
    
    /* ################################################################## */
    /**
     Called when the subviews are laid out. We use this to ensure that our segmented switch is set up correctly.
     */
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        
        guard let maxIndex = weekdayModeSelectorSegmentedSwitch?.numberOfSegments else { return }
        
        for index in (0..<maxIndex) {
            if 0 == index {
                weekdayModeSelectorSegmentedSwitch?.setTitle("SLUG-NOW".localizedVariant, forSegmentAt: index)
            } else if index == (maxIndex - 1) {
                weekdayModeSelectorSegmentedSwitch?.setImage(Self._searchImage, forSegmentAt: index)
            } else {
                let weekdayName = Calendar.current.veryShortStandaloneWeekdaySymbols[unMapWeekday(index) - 1]
                weekdayModeSelectorSegmentedSwitch?.setTitle(weekdayName, forSegmentAt: index)
            }
        }

        if isNameSearchMode {
            searchTextField?.becomeFirstResponder()
        }
    }
    
    /* ################################################################## */
    /**
     Called just before the view disappears.
     
     - parameter inIsAnimated: True, if the disappearance is animated.
     */
    override func viewWillDisappear(_ inIsAnimated: Bool) {
        super.viewWillDisappear(inIsAnimated)
        
        searchTextField?.resignFirstResponder()
        bottomConstraint?.constant = _atRestConstant
        
        NotificationCenter.default.removeObserver(
            self,
            name: UIResponder.keyboardWillShowNotification,
            object: nil
        )

        NotificationCenter.default.removeObserver(
            self,
            name: UIResponder.keyboardWillHideNotification,
            object: nil
        )
    }

    /* ################################################################## */
    /**
     Called before transitioning to another view controller.
     
     - parameter for: The segue instance.
     - parameter sender: ignored.
     */
    override func prepare(for inSegue: UIStoryboardSegue, sender: Any?) {
        if let destination = inSegue.destination as? VMF_DayTimeSearchPageViewController {
            destination.delegate = self
            destination.dataSource = self
            pageViewController = destination
        }
    }
}

/* ###################################################################################################################################### */
// MARK: UIPageViewControllerDataSource Conformance
/* ###################################################################################################################################### */
extension VMF_DayTimeSearchViewController: UIPageViewControllerDataSource {
    /* ################################################################## */
    /**
     Called to fetch the view controller before the current one.
     
     - parameter: The page view controller (ignored).
     - parameter viewControllerBefore: The view controller after (to the right of) the one we want.
     - returns: A new (or reused) view controller to appear before (to the left of) the "before" controller.
     */
    func pageViewController(_: UIPageViewController, viewControllerBefore inBeforeViewController: UIViewController) -> UIViewController? {
        guard !isNameSearchMode,
              let oldViewController = inBeforeViewController as? VMF_EmbeddedTableController
        else { return nil }
        
        var dayIndex = oldViewController.dayIndex
        var timeIndex = oldViewController.timeIndex
        timeIndex -= 1

        if 0 == dayIndex || 0 > timeIndex {
            if 0 == dayIndex {
                dayIndex = 7
            } else {
                dayIndex -= 1
                if 0 > dayIndex {
                    dayIndex = 7
                }
            }
            timeIndex = getDailyMeetings(for: mapWeekday(dayIndex)).keys.count - 1
        }
        
        return getTableDisplay(for: dayIndex, time: timeIndex)
    }
    
    /* ################################################################## */
    /**
     Called to fetch the view controller after the current one.
     
     - parameter: The page view controller (ignored).
     - parameter viewControllerBefore: The view controller before (to the left of) the one we want.
     - returns: A new (or reused) view controller to appear after (to the right of) the "before" controller.
     */
    func pageViewController(_: UIPageViewController, viewControllerAfter inAfterViewController: UIViewController) -> UIViewController? {
        guard !isNameSearchMode,
              let oldViewController = inAfterViewController as? VMF_EmbeddedTableController
        else { return nil }
        
        var timeIndex = oldViewController.timeIndex + 1
        var dayIndex = oldViewController.dayIndex
        
        if 0 == dayIndex {
            timeIndex = 0
            dayIndex = 1
        } else if timeIndex >= getDailyMeetings(for: mapWeekday(dayIndex)).count {
            dayIndex += 1
            timeIndex = 0

            if 7 < dayIndex {
                dayIndex = 0
            }
        }
        
        return getTableDisplay(for: dayIndex, time: timeIndex)
    }
}

/* ###################################################################################################################################### */
// MARK: UIPageViewControllerDelegate Conformance
/* ###################################################################################################################################### */
extension VMF_DayTimeSearchViewController: UIPageViewControllerDelegate {
    /* ################################################################## */
    /**
     Called when a swipe transition is done. The only thing we do here, is reset our trackers.
     
     - parameter: The page view controller (ignored).
     - parameter didFinishAnimating: The animation is complete (ignored)
     - parameter previousViewControllers: A list of previous view controllers (also ignored)
     - parameter transitionCompleted: True, if the transition completed, and was not aborted.
     */
    func pageViewController(_: UIPageViewController, didFinishAnimating: Bool, previousViewControllers: [UIViewController], transitionCompleted inIsDone: Bool) {
        if inIsDone {
            if isNameSearchMode {
                weekdayModeSelectorSegmentedSwitch?.selectedSegmentIndex = (weekdayModeSelectorSegmentedSwitch?.numberOfSegments ?? 1) - 1
            } else {
                weekdayModeSelectorSegmentedSwitch?.selectedSegmentIndex = tableDisplayController?.dayIndex ?? 0
            }
            
            timeDayDisplayLabel?.text = (tableDisplayController as? UIViewController)?.title
        }
    }
}

/* ###################################################################################################################################### */
// MARK: - Page View Controller -
/* ###################################################################################################################################### */
/**
 This is the page controller that embeds our tables.
 */
class VMF_DayTimeSearchPageViewController: UIPageViewController {
}
