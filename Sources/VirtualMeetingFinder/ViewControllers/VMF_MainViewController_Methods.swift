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

/* ###################################################################################################################################### */
// MARK: Instance Methods
/* ###################################################################################################################################### */
extension VMF_MainViewController {
    /* ################################################################## */
    /**
     This recalculates all the meeting data, breaking it into a couple of sorted arrays.
     */
    func reorganizeMeetings() {
        let exclude = VMF_AppDelegate.prefs.excludeServiceMeetings
        
        // First, we populate the search set, which a one-dimensional Array, sorted by meeting name, then timezone, then local start time.
        searchMeetings = VMF_AppDelegate.virtualService?.meetings.compactMap { !(exclude && $0.meeting.isServiceMeeting) ? $0.meeting : nil }.sorted { a, b in
            let aLower = a.name.lowercased()
            let bLower = b.name.lowercased()
            let aTZ = a.timeZone.secondsFromGMT()
            let bTZ = b.timeZone.secondsFromGMT()
            if aLower < bLower {
                return true
            } else if aLower > bLower {
                return false
            } else if aTZ < bTZ {
                return true
            } else if aTZ > bTZ {
                return false
            } else {
                return a.adjustedIntegerStartTime < b.adjustedIntegerStartTime
            }
        } ?? []
        
        // Next, we populate each weekday. This sorting is (local) weekday, local start time, then timezone, then meeting name. We sort into a two-dimensional Array, with the first dimension representing weekdays (Sunday(0) -> Saturday(6)).
        organizedMeetings = []
        for index in 1..<8 { // we start at 1 for Sunday, because that is how they are specified in the data.
            // Filter out the meetings just for this weekday.
            let weekdayMeetings = VMF_AppDelegate.virtualService?.meetings.compactMap { !(exclude && $0.meeting.isServiceMeeting) ? ((index == $0.meeting.adjustedWeekday) ? $0 : nil) : nil } ?? []
            
            // Then, we sort.
            let sortedWeekdayMeetings = weekdayMeetings.sorted { a, b in
                let aTZ = a.meeting.timeZone.secondsFromGMT()
                let bTZ = b.meeting.timeZone.secondsFromGMT()
                let timeComp = Calendar.current.compare(a.nextDate, to: b.nextDate, toGranularity: .minute)
                if .orderedAscending == timeComp {
                    return true
                } else if .orderedDescending == timeComp {
                    return false
                } else if aTZ < bTZ {
                    return false
                } else if aTZ > bTZ {
                    return true
                } else {
                    return a.meeting.name.lowercased() < b.meeting.name.lowercased()
                }
            }.map { $0.meeting }    // Finally, we extract just the meeting object.
            
            organizedMeetings.append(sortedWeekdayMeetings)
        }
    }
    
    /* ################################################################## */
    /**
     Called to load the meetings from the server.
     
     - parameter completion: A simple, no-parameter completion. It is always called in the main thread.
     */
    func loadMeetings(completion inCompletion: @escaping () -> Void) {
        isThrobbing = true
        VMF_AppDelegate.virtualService = nil
        
        VMF_AppDelegate.findMeetings { [weak self] inVirtualService in
            guard !(inVirtualService?.meetings.isEmpty ?? true)
            else {
                inCompletion()
                VMF_AppDelegate.displayAlert(header: "SLUG-ALERT-ERROR-HEADER", message: "SLUG-ALERT-ERROR-BODY", presentedBy: self)
                return
            }
            // This means that we won't arbitrarily reload.
            VMF_SceneDelegate.lastReloadTime = .distantFuture
            
            VMF_AppDelegate.virtualService = inVirtualService
            
            self?.reorganizeMeetings()
            
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
     - returns: a Dictionary, with the weekday's meetings, organized by localized start time (the key), which is expressed as military time (HHMM).
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
            newViewController.noRefresh = false
        } else if isNameSearchMode {
            newViewController.title = (tableDisplayController as? UIViewController)?.title
            newViewController.noRefresh = true
        } else if 0 == dayIndex {
            newViewController.title = "SLUG-IN-PROGRESS".localizedVariant
            newViewController.noRefresh = false
        }
        
        newViewController.noRefresh = isNameSearchMode || isDirectSelectionMode

        if (1..<8).contains(dayIndex) {
            lastTime = getTimeOf(dayIndex: dayIndex, timeIndex: timeIndex) ?? 0
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

            guard !tempMeetings.isEmpty,
                  !keys.isEmpty
            else { return [] }
            
            let timeIndex = max(0, min(inTimeIndex, keys.count - 1))
            let key = keys[timeIndex]
            meetings = tempMeetings[key] ?? []
        }
        
        return meetings
    }
    
    /* ################################################################## */
    /**
     This opens the screen to a certain day index, and time (not index).
     
     - parameter dayIndex: The 1-based (but 0 is in progress, 1-7 is Sunday through Saturday) day index. If omitted, then today/now is selected, and time is ignored.
     - parameter time: The military time (HHMM), as an integer. If omitted, 12AM (0000) is assumed.
     */
    func openTo(dayIndex inDayIndex: Int = -1, time inMilitaryTime: Int = 0) {
        let weekday = (0..<8).contains(inDayIndex) ? inDayIndex : -1 == inDayIndex ? nowIs.weekday : 0
        let time = (0..<8).contains(inDayIndex) && (0..<2400).contains(inMilitaryTime) ? inMilitaryTime : -1 == inDayIndex ? nowIs.currentIntegerTime : 0
        
        let nextIndex = getNearestIndex(dayIndex: weekday, time: time)
        guard let newViewController = getTableDisplay(for: weekday, time: nextIndex) else { return }
        
        pageViewController?.setViewControllers([newViewController], direction: .forward, animated: false)   // No animation. We make it quick.
        weekdayModeSelectorSegmentedSwitch?.selectedSegmentIndex = mapWeekday(weekday)
        
        timeDayDisplayLabel?.text = newViewController.title
    }
    
    /* ################################################################## */
    /**
     This returns the index of the time slot that is closest (before or after) to the given time and day.
     
     - parameter dayIndex: The 1-based day index. If omitted, then today/now is selected, and time is ignored.
     - parameter time: The military time (HHMM), as an integer. If omitted, 12AM (0000) is assumed.
     - returns: The index of the time slot closest to (or at the same time as) the given time. It may be prior.
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
     This updates the "thermometer" display in the time selector.
     */
    func updateThermometer(_ inTablePage: VMF_EmbeddedTableControllerProtocol?) {
        completionBar?.subviews.forEach { $0.removeFromSuperview() }
        
        guard let tablePage = inTablePage,
              let prevPage = tableDisplayController,
              let completionBar = completionBar,
              let repeatDuration = leftButton?.repeatFrequencyInSeconds,
              !isNameSearchMode
        else { return }
        
        let dayIndex = tablePage.dayIndex
        let prevTimeIndex = prevPage.timeIndex
        var timeIndex = tablePage.timeIndex

        var dailyMeetings = [Int: [MeetingInstance]]()
        var prevDailyMeetings = [Int: [MeetingInstance]]()

        if 0 == dayIndex {
            return // Not displayed for in progress mode.
        } else if 0 != prevPage.dayIndex {
            dailyMeetings = getDailyMeetings(for: dayIndex)
        
            guard (0..<dailyMeetings.count).contains(timeIndex) else { return }
        } else if 1 == dayIndex,
                  0 == prevPage.dayIndex {
            timeIndex = 0
        } else if 7 == dayIndex,
                  0 == prevPage.dayIndex {
            timeIndex = dailyMeetings.count - 1
        }
        
        prevDailyMeetings = 0 == prevPage.dayIndex ? [:] : getDailyMeetings(for: prevPage.dayIndex)

        let oldWidth = CGFloat(prevTimeIndex + 1) / max(1, CGFloat(prevDailyMeetings.count))
        let newWidth = CGFloat(timeIndex + 1) / max(1, CGFloat(dailyMeetings.count))
        let mercury = UIView()
        mercury.backgroundColor = Self.mercuryColor
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
    
    /* ################################################################## */
    /**
     Sets the day picker to whatever the current day/time is.
     */
    func setDayPicker() {
        guard let tableDisplayController = tableDisplayController else { return }
        let dayIndex = max(1, min(8, tableDisplayController.dayIndex)) - 1
        let timeIndex = tableDisplayController.timeIndex
        directSelectionPickerView?.selectRow(dayIndex, inComponent: 0, animated: true)
        directSelectionPickerView?.selectRow(timeIndex, inComponent: 1, animated: true)
    }
    
    /* ################################################################## */
    /**
     This enables or disables the attendance item.
     */
    func setAttendance() {
        myAttendanceBarButtonItem?.isEnabled = !(VMF_AppDelegate.virtualService?.meetingsThatIAttend.isEmpty ?? true)
    }
}

/* ###################################################################################################################################### */
// MARK: Callbacks
/* ###################################################################################################################################### */
extension VMF_MainViewController {
    /* ################################################################## */
    /**
     The segmented switch that controls the current display mode, was hit.
     
     - parameter inSwitch: The segmented switch.
     */
    @IBAction func weekdayModeSelectorSegmentedSwitchHit(_ inSwitch: UISegmentedControl) {
        let selectedIndex = inSwitch.selectedSegmentIndex
        let originalDayIndex = tableDisplayController?.dayIndex ?? 0
        var timeIndex = tableDisplayController?.timeIndex ?? 0
        if selectedIndex == (inSwitch.numberOfSegments - 1) {
            let dayIndex = tableDisplayController?.dayIndex ?? 0
            if !wasNameSearchMode {
                guard let newViewController = self.getTableDisplay(for: dayIndex, time: timeIndex) else { return }
                self.pageViewController?.setViewControllers([newViewController], direction: .forward, animated: false)
            }
            isNameSearchMode = true
        } else {
            isNameSearchMode = false
            let dayIndex = unMapWeekday(selectedIndex)
            
            // This whackiness, is because we want to try to set the time index to be as close as possible to the last one.
            if (1..<8).contains(dayIndex),
               0 < lastTime {
                timeIndex = getNearestIndex(dayIndex: dayIndex, time: lastTime)
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
        selectionHaptic()
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
                successHaptic()
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
                successHaptic()
            }
            
            guard let newViewController = getTableDisplay(for: dayIndex, time: timeIndex) else { return }
            pageViewController?.setViewControllers([newViewController], direction: .reverse, animated: false)
            weekdayModeSelectorSegmentedSwitch?.selectedSegmentIndex = mapWeekday(dayIndex)
            timeDayDisplayLabel?.text = (tableDisplayController as? UIViewController)?.title
        }
    }
    
    /* ################################################################## */
    /**
     The double-tap gesture recognizer on the weekday/time display label was triggered.
     
     This resets the screen to today/now.
     
     - parameter: ignored
     */
    @IBAction func doubleTapOnDayTimeLabel(_: Any) {
        if !isNameSearchMode {
            hardImpactHaptic()
            openTo()
        }
    }
    
    /* ############################################################## */
    /**
     A long-press on the weekday switch was detected. We change the weekday (we do not change to in-progress or search).
     
     - parameter inGestureRecognizer: The gesture recognizer that was triggered.
     */
    @IBAction func longPressGestureInWeekdaySwitchDetected(_ inGestureRecognizer: UILongPressGestureRecognizer) {
        guard let weekdayModeSelectorSegmentedSwitch = weekdayModeSelectorSegmentedSwitch else { return }
        
        let width = weekdayModeSelectorSegmentedSwitch.bounds.size.width
        let selectedSegment = weekdayModeSelectorSegmentedSwitch.selectedSegmentIndex
        let numberOfSegments = weekdayModeSelectorSegmentedSwitch.numberOfSegments
        let gestureLocation = inGestureRecognizer.location(ofTouch: 0, in: weekdayModeSelectorSegmentedSwitch)
        var location = gestureLocation.x
        let stepSize = width / CGFloat(numberOfSegments)
        var steps = [(start: CGFloat, end: CGFloat)]()
        for index in 1..<(numberOfSegments - 1) {
            let start = CGFloat(index) * stepSize
            let end = start + stepSize
            steps.append((start: start, end: end))
        }
        
        switch inGestureRecognizer.state {
        case .began, .changed:
            if .began == inGestureRecognizer.state || location != oldLocation {
                var selectedIndex = -1
                for enumeration in steps.enumerated() {
                    let testRange = enumeration.element.start..<enumeration.element.end
                    if testRange.contains(location) {
                        selectedIndex = enumeration.offset + 1
                        break
                    }
                }
                
                if .began == inGestureRecognizer.state || selectedIndex != selectedSegment,
                   (1..<(numberOfSegments - 1)).contains(selectedIndex) {
                    if .began == inGestureRecognizer.state {
                        hardImpactHaptic()
                    }
                    weekdayModeSelectorSegmentedSwitch.selectedSegmentIndex = selectedIndex
                    weekdayModeSelectorSegmentedSwitch.sendActions(for: .valueChanged)
                }
            }
        
        default:
            location = 0
        }
        
        oldLocation = location
    }

    /* ############################################################## */
    /**
     A long-press on the day/time display label switch was detected. We change the time slot.
     
     - parameter inGestureRecognizer: The gesture recognizer that was triggered.
     */
    @IBAction func longPressGestureInDisplayLabelDetected(_ inGestureRecognizer: UILongPressGestureRecognizer) {
        guard let view = view,
              let dayIndex = tableDisplayController?.dayIndex,
              (1..<8).contains(dayIndex),
              0 < view.bounds.size.width
        else { return }
        
        let timeSlots = getDailyMeetings(for: dayIndex)
        let gestureLocation = inGestureRecognizer.location(ofTouch: 0, in: view)
        let fraction = gestureLocation.x / view.bounds.size.width
        let timeSlot = max(0, min(timeSlots.count - 1, Int(round(fraction * CGFloat(timeSlots.count)))))
        
        switch inGestureRecognizer.state {
        case .began, .changed:
            if timeSlot != Int(oldLocation),
               let time = getTimeOf(dayIndex: dayIndex, timeIndex: timeSlot) {
                if .began == inGestureRecognizer.state {
                    hardImpactHaptic()
                }
                
                openTo(dayIndex: dayIndex, time: time)
            }
            oldLocation = CGFloat(timeSlot)

        default:
            oldLocation = 0
        }
        
    }

    /* ################################################################## */
    /**
     The weekday/time label was touched.
     
     - parameter: ignored.
     */
    @IBAction func directSelectionOpen(_: Any) {
        if 0 < (tableDisplayController?.dayIndex ?? 0) {
            isDirectSelectionMode = true
        }
    }

    /* ################################################################## */
    /**
     The close button for the direct selection mode was hit.
     
     - parameter: ignored.
     */
    @IBAction func directSelectionCloseButtonHit(_: Any) {
        isDirectSelectionMode = false
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
            self?.bottomConstraint?.constant = self?.atRestConstant ?? 0
        }
    }
    
    /* ################################################################## */
    /**
     Reloads all the meetings.
     
     - parameter completion: A simple empty callback. Always called in the main thread.
     */
    func refreshCalled(completion inCompletion: @escaping () -> Void) {
        guard !isNameSearchMode else { return }
        hardImpactHaptic()
        loadMeetings(completion: inCompletion)
    }
}

/* ###################################################################################################################################### */
// MARK: Base Class Overrides
/* ###################################################################################################################################### */
extension VMF_MainViewController {
    /* ################################################################## */
    /**
     Called when the view hierarchy loads.
     */
    override func viewDidLoad() {
        super.viewDidLoad()
        navigationItem.title = "SLUG-TAB-0-TITLE".localizedVariant
        VMF_AppDelegate.searchController = self
        searchTextField?.placeholder = searchTextField?.placeholder?.localizedVariant
        myAttendanceBarButtonItem?.isAccessibilityElement = true
        myAttendanceBarButtonItem?.accessibilityLabel = "SLUG-ACC-TAB-1-BUTTON-LABEL"
        myAttendanceBarButtonItem?.accessibilityHint = "SLUG-ACC-TAB-1-BUTTON-HINT"
        settingsBarButtonItem?.isAccessibilityElement = true
        settingsBarButtonItem?.accessibilityLabel = "SLUG-ACC-SETTINGS-BUTTON-LABEL"
        settingsBarButtonItem?.accessibilityHint = "SLUG-ACC-SETTINGS-BUTTON-HINT"
        weekdayModeSelectorSegmentedSwitch?.accessibilityLabel = "SLUG-ACC-WEEKDAY-SWITCH-LABEL"
        weekdayModeSelectorSegmentedSwitch?.accessibilityHint = "SLUG-ACC-WEEKDAY-SWITCH-HINT"

        atRestConstant = bottomConstraint?.constant ?? 0

        guard let numberOfSegments = weekdayModeSelectorSegmentedSwitch?.numberOfSegments,
              0 < numberOfSegments,
              8 < numberOfSegments
        else { return }
        
        var titleTextAttributes = [NSAttributedString.Key.foregroundColor: UIColor.tintColor, NSAttributedString.Key.font: UIFont.boldSystemFont(ofSize: 20)]
        UISegmentedControl.appearance().setTitleTextAttributes(titleTextAttributes, for: .normal)
        
        titleTextAttributes = [NSAttributedString.Key.foregroundColor: UIColor.label, NSAttributedString.Key.font: UIFont.systemFont(ofSize: 20)]
        UISegmentedControl.appearance().setTitleTextAttributes(titleTextAttributes, for: .selected)

        weekdayModeSelectorSegmentedSwitch?.apportionsSegmentWidthsByContent = true
        (weekdayModeSelectorSegmentedSwitch?.accessibilityElement(at: 0) as? UIView)?.accessibilityLabel = "SLUG-ACC-WEEKDAY-SWITCH-0-LABEL"
        (weekdayModeSelectorSegmentedSwitch?.accessibilityElement(at: 0) as? UIView)?.accessibilityHint = "SLUG-ACC-WEEKDAY-SWITCH-0-HINT"

        for index in (1..<(numberOfSegments - 1)) {
            let weekday = Calendar.current.standaloneWeekdaySymbols[mapWeekday(index) - 1]
            (weekdayModeSelectorSegmentedSwitch?.accessibilityElement(at: index) as? UIView)?.accessibilityLabel = String(format: "SLUG-ACC-WEEKDAY-SWITCH-WEEKDAY-LABEL-FORMAT".accessibilityLocalizedVariant, weekday)
            (weekdayModeSelectorSegmentedSwitch?.accessibilityElement(at: index) as? UIView)?.accessibilityHint = String(format: "SLUG-ACC-WEEKDAY-SWITCH-WEEKDAY-HINT-FORMAT".accessibilityLocalizedVariant, weekday)
        }

        (weekdayModeSelectorSegmentedSwitch?.accessibilityElement(at: 8) as? UIView)?.accessibilityLabel = "SLUG-ACC-WEEKDAY-SWITCH-8-LABEL"
        (weekdayModeSelectorSegmentedSwitch?.accessibilityElement(at: 8) as? UIView)?.accessibilityHint = "SLUG-ACC-WEEKDAY-SWITCH-8-HINT"
        
        guard let labelDoubleTapGesture = labelDoubleTapGesture else { return }
        directSelectionTapRecognizer?.require(toFail: labelDoubleTapGesture)
        
        timeDayDisplayLabel?.textColor = .tintColor
        
        isDirectSelectionMode = false
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
        
        isDirectSelectionMode = false
        if organizedMeetings.isEmpty {
            reorganizeMeetings()
            view?.setNeedsLayout()
        }
        
        if VMF_SceneDelegate.forceReloadDelayInSeconds < -VMF_SceneDelegate.lastReloadTime.timeIntervalSinceNow {
            isNameSearchMode = false
        } else {
            isNameSearchMode = wasNameSearchMode
        }
        
        setAttendance()
    }
    
    /* ################################################################## */
    /**
     Called just after the view appears.
     
     - parameter inIsAnimated: True, if the appearance is animated.
     */
    override func viewDidAppear(_ inIsAnimated: Bool) {
        super.viewDidAppear(inIsAnimated)
        
        if VMF_SceneDelegate.forceReloadDelayInSeconds < -VMF_SceneDelegate.lastReloadTime.timeIntervalSinceNow {
            loadMeetings { self.openTo() }
        }
        
        // This means that we won't arbitrarily reload.
        VMF_SceneDelegate.lastReloadTime = .distantFuture
        
        (tableDisplayController as? VMF_EmbeddedTableController)?.noRefresh = isNameSearchMode
    }
    
    /* ################################################################## */
    /**
     Called when the subviews are laid out. We use this to ensure that our segmented switch is set up correctly.
     */
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        setAttendance()

        guard let maxIndex = weekdayModeSelectorSegmentedSwitch?.numberOfSegments,
              let windowWidth = view?.bounds.size.width
        else { return }

        for index in (0..<maxIndex) {
            if 0 == index {
                weekdayModeSelectorSegmentedSwitch?.setTitle("SLUG-NOW".localizedVariant, forSegmentAt: index)
            } else if index == (maxIndex - 1) {
                weekdayModeSelectorSegmentedSwitch?.setImage(Self.searchImage, forSegmentAt: index)
            } else {
                let wdIndex = unMapWeekday(index) - 1
                // We try to use the largest weekday indicator possible.
                let weekdayName = Self.shortWidthThreshold > windowWidth
                    ? Calendar.current.veryShortStandaloneWeekdaySymbols[wdIndex]   // Single letter
                    : Self.fullWidthThreshold > windowWidth
                        ? Calendar.current.shortStandaloneWeekdaySymbols[wdIndex]   // Abbreviation
                        : Calendar.current.standaloneWeekdaySymbols[wdIndex]        // Full word
                
                weekdayModeSelectorSegmentedSwitch?.setTitle(weekdayName, forSegmentAt: index)
            }
        }
    }
    
    /* ################################################################## */
    /**
     Called just before the view disappears.
     
     - parameter inIsAnimated: True, if the disappearance is animated.
     */
    override func viewWillDisappear(_ inIsAnimated: Bool) {
        super.viewWillDisappear(inIsAnimated)
        wasNameSearchMode = isNameSearchMode

        searchTextField?.resignFirstResponder()
        bottomConstraint?.constant = atRestConstant
        
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
        } else if inSegue.destination is VMF_AttendanceViewController || inSegue.destination is VMF_SettingsViewController {
            hardImpactHaptic()
        }
    }
}
