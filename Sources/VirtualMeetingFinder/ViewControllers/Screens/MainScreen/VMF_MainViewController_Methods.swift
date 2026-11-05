/*
 © Copyright 2024-2026, Little Green Viper Software Development LLC
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
      Sets up the localized, accessible navigation title button.
      */
     private func _setUpDayTimeSelectionButton() {
          var configuration = UIButton.Configuration.plain()
          configuration.image = UIImage(systemName: "chevron.down")
          configuration.imagePlacement = .trailing
          configuration.imagePadding = 4
          configuration.titleAlignment = .center
          configuration.titleLineBreakMode = .byTruncatingTail
          configuration.contentInsets = NSDirectionalEdgeInsets(top: 0, leading: 4, bottom: 0, trailing: 4)
          configuration.titleTextAttributesTransformer = UIConfigurationTextAttributesTransformer { attributes in
               var attributes = attributes
               attributes.font = UIFont.preferredFont(forTextStyle: .headline)
               return attributes
          }
          dayTimeSelectionButton.configuration = configuration
          dayTimeSelectionButton.titleLabel?.adjustsFontForContentSizeCategory = true
          dayTimeSelectionButton.titleLabel?.adjustsFontSizeToFitWidth = true
          dayTimeSelectionButton.titleLabel?.minimumScaleFactor = 0.65
          dayTimeSelectionButton.titleLabel?.numberOfLines = 2
          dayTimeSelectionButton.titleLabel?.textAlignment = .center
          dayTimeSelectionButton.titleLabel?.lineBreakMode = .byTruncatingTail
          dayTimeSelectionButton.heightAnchor.constraint(equalToConstant: 44).isActive = true
          dayTimeSelectionButton.widthAnchor.constraint(greaterThanOrEqualToConstant: 44).isActive = true
          dayTimeSelectionButton.isAccessibilityElement = true
          dayTimeSelectionButton.accessibilityLabel = "SLUG-ACC-DAY-TIME-BUTTON-LABEL".localizedVariant
          dayTimeSelectionButton.accessibilityHint = "SLUG-ACC-DAY-TIME-BUTTON-HINT".localizedVariant
          dayTimeSelectionButton.accessibilityIdentifier = "day-time-selection-button"
          dayTimeSelectionButton.addTarget(self, action: #selector(dayTimeSelectionButtonHit), for: .touchUpInside)
          navigationItem.titleView = dayTimeSelectionButton
          updateDayTimeSelectionButton()
     }

     /* ################################################################## */
     /**
      Keeps the navigation button and its spoken value in sync with the displayed table.
      Search and in-progress modes use their localized descriptions instead of a time slot.
      */
     func updateDayTimeSelectionButton() {
          let selectionTitle = isNameSearchMode
               ? "SLUG-SEARCH-MODE-TITLE".localizedVariant
               : (tableDisplayController as? UIViewController)?.title ?? "SLUG-ACC-DIRECT-PICKER-LABEL".localizedVariant
          dayTimeSelectionButton.setTitle(selectionTitle, for: .normal)
          dayTimeSelectionButton.accessibilityValue = isNameSearchMode ? "SLUG-ACC-WEEKDAY-SWITCH-8-LABEL".localizedVariant : selectionTitle
          dayTimeSelectionButton.sizeToFit()
          navigationController?.navigationBar.setNeedsLayout()
          if let popover = presentedViewController?.popoverPresentationController,
             popover.sourceView === dayTimeSelectionButton {
               navigationController?.navigationBar.layoutIfNeeded()
               popover.sourceRect = dayTimeSelectionButton.bounds
          }
     }

     /* ################################################################## */
     /**
      Closes the day/time popover and its keyboard when the scene enters the background.
      Dismisses without animation so suspension cannot leave an unfinished presentation on screen.
      */
     func dismissDayTimeSelectionPopover() {
          guard let controller = presentedViewController as? VMF_DayTimeSelectionViewController else { return }
          controller.viewIfLoaded?.endEditing(true)
          controller.dismiss(animated: false)
     }

     /* ################################################################## */
     /**
      Reveals the first main screen after loading and laying out its navigation bar.
      */
     private func _finishLaunching() {
          UIView.performWithoutAnimation {
               removeNavigationBarItemBackgrounds()
               navigationController?.view.layoutIfNeeded()
          }
          (view.window?.windowScene?.delegate as? VMF_SceneDelegate)?.finishLaunching()
     }

     /* ################################################################## */
     /**
      This recalculates all the meeting data, breaking it into a couple of sorted arrays.
      */
     func reorganizeMeetings() {
          let exclude = VMF_AppDelegate.prefs.excludeServiceMeetings
          
          // First, we populate the search set, which is a one-dimensional Array, sorted by meeting name, then timezone, then local start time.
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
      
      - parameter inCompletion: A simple, no-parameter completion. It is always called in the main thread.
      */
     func loadMeetings(completion inCompletion: @escaping () -> Void) {
          isThrobbing = true
          VMF_AppDelegate.virtualService = nil
          
          VMF_AppDelegate.findMeetings { [weak self] inVirtualService in
               guard !(inVirtualService?.meetings.isEmpty ?? true)
               else {
                    VMF_AppDelegate.displayAlert(header: "SLUG-ALERT-ERROR-HEADER", message: "SLUG-ALERT-ERROR-BODY", presentedBy: self)
                    self?.isThrobbing = false
                    inCompletion()
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
      
      - parameter inWeekdayIndex: The 1-based (1 is Sunday) weekday index
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
      
      - parameter inDayIndex: The 0-based "day index." If it is 0, though, it is the "in-progress" display.
      - parameter inTimeIndex: The 0-based time index. This is the index of the currently selected time slot.
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
             
             if let testMeeting = meetings.first {
                 let nextDate = testMeeting.nextOccurrenceDateFast()
                 
                 let timeFormatter = DateFormatter()
                 timeFormatter.locale = .current
                 timeFormatter.timeZone = .autoupdatingCurrent
                 timeFormatter.dateStyle = .none
                 timeFormatter.timeStyle = .short
                 
                 let timeString = timeFormatter.string(from: nextDate)
                 let weekdayString = Calendar.current.weekdaySymbols[dayIndex - 1]
                 
                 newViewController.title = String(
                     format: "SLUG-WEEKDAY-TIME-FORMAT".localizedVariant,
                     weekdayString,
                     timeString
                 )
             } else {
                 // An empty weekday has no time slot, but still needs a localized title.
                 newViewController.title = Calendar.current.weekdaySymbols[dayIndex - 1]
             }
             
             newViewController.noRefresh = false
         } else if isNameSearchMode {
             newViewController.title = "SLUG-SEARCH-MODE-TITLE".localizedVariant
             newViewController.noRefresh = true
         } else if 0 == dayIndex {
             newViewController.title = "SLUG-IN-PROGRESS".localizedVariant
             newViewController.noRefresh = false
         }
         
         newViewController.noRefresh = isNameSearchMode

         return newViewController
     }
     
     /* ################################################################## */
     /**
      This returns the meetings we should display, given the day and time.
      
      NOTE: If the controller is in text search mode, then the search set is returned.
      
      - parameter inDayIndex: The 0-based "day index." If it is 0, though, it is the "in-progress" display.
      - parameter inTimeIndex: The 0-based time index. This is the index of the currently selected time slot.
      - returns: A new (or reused) view controller, for the destination of the transition.
      */
     func getCurentMeetings(for inDayIndex: Int = 0, time inTimeIndex: Int = 0) -> [MeetingInstance] {
          var meetings = [MeetingInstance]()
          
          if isNameSearchMode {
               if searchText.isEmpty {
                    meetings = searchMeetings
               } else {
                    let query = searchText.meetingSearchKey
                    meetings = zip(searchMeetings, searchMeetingNames).compactMap { $0.1.contains(query) ? $0.0 : nil }
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
      
      - parameter inDayIndex: The 1-based (but 0 is in progress, 1-7 is Sunday through Saturday) day index. If omitted, then today/now is selected, and time is ignored.
      - parameter inMilitaryTime: The military time (HHMM), as an integer. If omitted, 12AM (0000) is assumed.
      */
     func openTo(dayIndex inDayIndex: Int = -1, time inMilitaryTime: Int = 0) {
          let weekday = (0..<8).contains(inDayIndex) ? inDayIndex : -1 == inDayIndex ? nowIs.weekday : 0
          let time = (0..<8).contains(inDayIndex) && (0..<2400).contains(inMilitaryTime) ? inMilitaryTime : -1 == inDayIndex ? nowIs.currentIntegerTime : 0
          
          isNameSearchMode = false
          let nextIndex = getNearestIndex(dayIndex: weekday, time: time)
          guard let newViewController = getTableDisplay(for: weekday, time: nextIndex) else { return }
          
          pageViewController?.setViewControllers([newViewController], direction: .forward, animated: false)   // No animation. We make it quick.
          tableDisplayController = newViewController
     }
     
     /* ################################################################## */
     /**
      This returns the index of the time slot that is closest (before or after) to the given time and day.
      
      - parameter inDayIndex: The 1-based day index. If omitted, then today/now is selected, and time is ignored.
      - parameter inMilitaryTime: The military time (HHMM), as an integer. If omitted, 12AM (0000) is assumed.
      - returns: The index of the time slot closest to (or at the same time as) the given time. It may be prior.
      */
     func getNearestIndex(dayIndex inDayIndex: Int = -1, time inMilitaryTime: Int = 0) -> Int {
          let weekday = (1..<8).contains(inDayIndex) ? inDayIndex : -1 == inDayIndex ? nowIs.weekday : 0
          let time = (1..<8).contains(inDayIndex) && (0..<2400).contains(inMilitaryTime) ? inMilitaryTime : -1 == inDayIndex ? nowIs.currentIntegerTime : 0
          
          let dailyKeys = getDailyMeetings(for: weekday).keys.sorted()
          let targetMinutes = (time / 100) * 60 + time % 100
          return dailyKeys.indices.min {
               let firstMinutes = (dailyKeys[$0] / 100) * 60 + dailyKeys[$0] % 100
               let secondMinutes = (dailyKeys[$1] / 100) * 60 + dailyKeys[$1] % 100
               return abs(firstMinutes - targetMinutes) < abs(secondMinutes - targetMinutes)
          } ?? 0
     }
     
     /* ################################################################## */
     /**
      This returns the time that corresponds to the day and time presented.
      
      - parameter inDayIndex: The 1-based day index.
      - parameter inTimeIndex: The index, as a 0-based integer.
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
      Opens the day and time popover from the navigation title button.
      */
     @objc func dayTimeSelectionButtonHit() {
          guard nil == presentedViewController else { return }

          let controller = VMF_DayTimeSelectionViewController()
          controller.mainController = self
          controller.modalPresentationStyle = .popover
          controller.preferredContentSize = VMF_DayTimeSelectionViewController.browsingSize
          guard let popover = controller.popoverPresentationController else { return }
          popover.delegate = controller
          popover.sourceView = dayTimeSelectionButton
          popover.sourceRect = dayTimeSelectionButton.bounds
          popover.permittedArrowDirections = .up
          popover.backgroundColor = VMF_DayTimeSelectionViewController.backgroundColor
          popover.popoverBackgroundViewClass = VMF_DayTimePopoverBackgroundView.self
          present(controller, animated: true)
     }

     /* ################################################################## */
     /**
      Reloads all the meetings.
      
      - parameter inCompletion: A simple empty callback. Always called in the main thread.
      */
     func refreshCalled(completion inCompletion: @escaping () -> Void) {
          guard !isNameSearchMode else { return }
          hardImpactHaptic()
          let day = tableDisplayController?.dayIndex ?? 0
          let time = getTimeOf(dayIndex: day, timeIndex: tableDisplayController?.timeIndex ?? 0) ?? lastTime
          loadMeetings {
               self.openTo(dayIndex: day, time: time)
               inCompletion()
          }
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
          _setUpDayTimeSelectionButton()
          VMF_AppDelegate.mainScreenController = self
          swipeLabel?.text = swipeLabel?.text?.localizedVariant
          myAttendanceBarButtonItem?.isAccessibilityElement = true
          myAttendanceBarButtonItem?.accessibilityLabel = "SLUG-ACC-TAB-1-BUTTON-LABEL".localizedVariant
          myAttendanceBarButtonItem?.accessibilityHint = "SLUG-ACC-TAB-1-BUTTON-HINT".localizedVariant
          settingsBarButtonItem?.isAccessibilityElement = true
          settingsBarButtonItem?.accessibilityLabel = "SLUG-ACC-SETTINGS-BUTTON-LABEL".localizedVariant
          settingsBarButtonItem?.accessibilityHint = "SLUG-ACC-SETTINGS-BUTTON-HINT".localizedVariant

          if let swipeLabel = swipeLabel {
               swipeLabel.bottomAnchor.constraint(equalTo: view.keyboardLayoutGuide.topAnchor, constant: -8).isActive = true
          }
     }
     
     /* ################################################################## */
     /**
      Called just before the view is to appear.
      
      - parameter inIsAnimated: True, if the appearance is animated.
      */
     override func viewWillAppear(_ inIsAnimated: Bool) {
          super.viewWillAppear(inIsAnimated)
          
          if organizedMeetings.isEmpty { reorganizeMeetings() }
          if needsReload { isNameSearchMode = false }
          setAttendance()
     }
     
     /* ################################################################## */
     /**
      Called just after the view appears.
      
      - parameter inIsAnimated: True, if the appearance is animated.
      */
     override func viewDidAppear(_ inIsAnimated: Bool) {
          super.viewDidAppear(inIsAnimated)

          // If we have to load from the meeting server, we do so, now.
          if needsReload {
               loadMeetings {
                    self.openTo(dayIndex: 0)
                    self._finishLaunching()
               }
          } else {
               _finishLaunching()
          }
          
          // This means that we won't arbitrarily reload.
          VMF_SceneDelegate.lastReloadTime = .distantFuture
          
          // This ensures that we have a pull-to-refresh, as long as we are not in search mode.
          (tableDisplayController as? VMF_EmbeddedTableController)?.noRefresh = isNameSearchMode
     }
     
     /* ################################################################## */
     /**
      Updates the attendance button after layout.
      */
     override func viewDidLayoutSubviews() {
          super.viewDidLayoutSubviews()
          setAttendance()
     }
     
     /* ################################################################## */
     /**
      Called before transitioning to another view controller.
      
      - parameter inSegue: The segue instance.
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
