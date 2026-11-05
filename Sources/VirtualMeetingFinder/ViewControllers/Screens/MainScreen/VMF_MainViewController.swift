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

/* ###################################################################################################################################### */
// MARK: - Search View Controller -
/* ###################################################################################################################################### */
/**
 Coordinates the main meeting list, time-slot paging, and meeting-name search.

 ## Selection model

 Day indexes use 0 for meetings in progress and 1 through 7 for Sunday through Saturday.
 ``isNameSearchMode`` enables name search independently of the stored day and time indexes;
 search is not a weekday index. A time index is a zero-based position among the sorted,
 distinct local start times for a weekday. ``lastTime`` stores an HHMM value instead.

 ``VMF_DayTimeSelectionViewController`` presents the weekday/time picker and search field
 from the navigation title button. ``VMF_DayTimeSearchPageViewController`` embeds the
 current meeting table and allows adjacent time-slot swipes outside search mode.
 Selecting Now explicitly displays all meetings in progress. The first swipe from Now
 selects the latest available start at or before the current local time.

 Search filters the name-sorted collection as text changes and preserves the underlying
 time selection. Local attendance selections are available from a separate
 ``VMF_AttendanceViewController`` screen when at least one meeting is marked.
 */
class VMF_MainViewController: VMF_BaseViewController, VMF_MasterTableControllerProtocol {
     /// Storyboard segue used to open the attendance screen.
     static let openAttendanceSegueID = "open-attendance"
     /// Filled attendance icon.
     static let checkedImage = UIImage(systemName: "checkmark.square.fill")
     /// Empty attendance icon.
     static let uncheckedImage = UIImage(systemName: "square")
     /// Font for compact navigation labels.
     static let barButtonLabelFont = UIFont.systemFont(ofSize: 15)

     /** The last selected start time, preserved when entering Now or search. */
     var lastTime = 0

     /** The currently displayed page also supplies the navigation button's title. */
     var tableDisplayController: VMF_EmbeddedTableControllerProtocol? {
          didSet {
               if !isNameSearchMode,
                  let page = tableDisplayController,
                  let time = getTimeOf(dayIndex: page.dayIndex, timeIndex: page.timeIndex) {
                    lastTime = time
               }
               updateDayTimeSelectionButton()
          }
     }

     /// Navigation title control that opens the day/time and search popover.
     let dayTimeSelectionButton = UIButton(type: .system)
     /// Storyboard page controller hosting the current meeting table.
     weak var pageViewController: VMF_DayTimeSearchPageViewController?

     /** Meetings sorted by name for search, and by weekday for time selection. */
     var searchMeetings: [MeetingInstance] = [] {
          didSet { searchMeetingNames = searchMeetings.map { $0.name.meetingSearchKey } }
     }
     /// Normalized names parallel to the name-sorted meeting array.
     private(set) var searchMeetingNames: [String] = []
     /// Local weekday groups: index 0 is Sunday, index 6 is Saturday.
     var organizedMeetings: [[MeetingInstance]] = []

     /** Search retains the underlying weekday/time selection for returning to browsing. */
     var isNameSearchMode = false {
          didSet {
               guard oldValue != isNameSearchMode else { return }
               pageViewController?.dataSource = nil
               if !isNameSearchMode {
                    pageViewController?.dataSource = self
               }
               if let page = tableDisplayController,
                  let controller = getTableDisplay(for: page.dayIndex, time: page.timeIndex) {
                    pageViewController?.setViewControllers([controller], direction: .forward, animated: false)
                    tableDisplayController = controller
               }
               swipeLabel?.isHidden = isNameSearchMode
               updateDayTimeSelectionButton()
               successHaptic()
          }
     }

     /// Retained name query; changing it refreshes the table only while searching.
     var searchText = "" {
          didSet {
               if isNameSearchMode {
                    tableDisplayController?.meetings = getCurentMeetings()
               }
          }
     }

     /// Hides navigation and results while meeting data is loading.
     var isThrobbing = false {
          didSet {
               navigationController?.isNavigationBarHidden = isThrobbing
               tabBarController?.tabBar.isHidden = isThrobbing
               tableContainerView?.isHidden = isThrobbing
               swipeLabel?.isHidden = isThrobbing || isNameSearchMode
               throbber?.isHidden = !isThrobbing
               if !isThrobbing { setAttendance() }
          }
     }

     /// Visual instruction for moving between meeting time slots.
     @IBOutlet weak var swipeLabel: UILabel?
     /// Opens app settings.
     @IBOutlet weak var settingsBarButtonItem: UIBarButtonItem?
     /// Opens saved attendance; disabled when the attendance list is empty.
     @IBOutlet weak var myAttendanceBarButtonItem: UIBarButtonItem?
     /// Contains the embedded time-slot page controller.
     @IBOutlet weak var tableContainerView: UIView?
     /// Loading indicator container.
     @IBOutlet weak var throbber: UIView?
}

/* ###################################################################################################################################### */
// MARK: Base Class Overrides (Computed Properties)
/* ###################################################################################################################################### */
extension VMF_MainViewController {
     /* ################################################################## */
     /**
      Requests automatic hiding of the home indicator on supported devices.
      */
     override var prefersHomeIndicatorAutoHidden: Bool { true }
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
         VMF_AppDelegate.virtualService?.meetings
             .compactMap { $0.isInProgress ? $0.meeting : nil }
             .sorted { a, b in
                 let aDate = a.previousOccurrenceDateFast()
                 let bDate = b.previousOccurrenceDateFast()
                 
                 if aDate < bDate {
                     return true
                 } else if aDate > bDate {
                     return false
                 } else if a.timeZone.secondsFromGMT(for: aDate) < b.timeZone.secondsFromGMT(for: bDate) {
                     return true
                 } else if a.timeZone.secondsFromGMT(for: aDate) > b.timeZone.secondsFromGMT(for: bDate) {
                     return false
                 } else {
                     return a.name.localizedCaseInsensitiveCompare(b.name) == .orderedAscending
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
