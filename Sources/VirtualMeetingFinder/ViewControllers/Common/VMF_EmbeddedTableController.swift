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
// MARK: - Base Protocol -
/* ###################################################################################################################################### */
/**
 Protocol for both owners and tables
 */
protocol VMF_BaseProtocol: NSObjectProtocol {
     /* ################################################################## */
     /**
      The controller that "owns" this instance.
      */
     var myController: (any VMF_MasterTableControllerProtocol)? { get set }
}

/* ###################################################################################################################################### */
// MARK: Defaults
/* ###################################################################################################################################### */
extension VMF_BaseProtocol {
     /* ################################################################## */
     /**
      Default is nil
      */
     var myController: (any VMF_MasterTableControllerProtocol)? { get { nil } set { _ = newValue } }
}

/* ###################################################################################################################################### */
// MARK: - Protocol for Table Display -
/* ###################################################################################################################################### */
/**
 Protocol for embedded tables.
 */
protocol VMF_EmbeddedTableControllerProtocol: VMF_BaseProtocol {
     /* ################################################################## */
     /**
      The day index for this table.
      */
     var dayIndex: Int { get set }
     
     /* ################################################################## */
     /**
      The index for this table.
      */
     var timeIndex: Int { get set }
     
     /* ################################################################## */
     /**
      This handles the meeting collection for this.
      */
     var meetings: [MeetingInstance] { get set }
     
     /* ################################################################## */
     /**
      The table that shows the meetings for the current selection.
      */
     var valueTable: UITableView? { get }
}

/* ###################################################################################################################################### */
// MARK: - Protocol for "Owners" of Table Display -
/* ###################################################################################################################################### */
/**
 Protocol for owners
 */
protocol VMF_MasterTableControllerProtocol: VMF_BaseProtocol {
     /* ################################################################## */
     /**
      This tracks embedded table controllers.
      */
     var tableDisplayController: VMF_EmbeddedTableControllerProtocol? { get set }
     
     /* ################################################################## */
     /**
      Called when a refresh is needed.
      
      - parameter completion: A simple, no-parameter completion. It is always called in the main thread.
      */
     func refreshCalled(completion: @escaping () -> Void)
     
     /* ################################################################## */
     /**
      This updates the "thermometer" display, in the time selector.
      */
     func updateThermometer(_ inTablePage: VMF_EmbeddedTableControllerProtocol?)
     
     /* ################################################################## */
     /**
      This sets the day picker, if we have one.
      */
     func setDayPicker()
     
     /* ################################################################## */
     /**
      This enables or disables the attendance item.
      */
     func setAttendance()
}

/* ###################################################################################################################################### */
// MARK: Defaults
/* ###################################################################################################################################### */
extension VMF_MasterTableControllerProtocol {
     /* ################################################################## */
     /**
      Default does nothing
      */
     func refreshCalled(completion inCompletion: @escaping () -> Void) { inCompletion() }
     
     /* ################################################################## */
     /**
      Default does nothing
      */
     func setDayPicker() { }
     
     /* ################################################################## */
     /**
      Default does nothing
      */
     func setAttendance() { }
     
     /* ################################################################## */
     /**
      This updates the "thermometer" display, in the time selector.
      */
     func updateThermometer(_ inTablePage: VMF_EmbeddedTableControllerProtocol?) { }
}

/* ###################################################################################################################################### */
// MARK: - Custom Table Cell View -
/* ###################################################################################################################################### */
/**
 This provides one table cell for the main table of meetings.
 */
class VMF_TableCell: UITableViewCell {
     /* ################################################################## */
     /**
      This is the reuse ID for the table cell.
      */
     static let reuseID = "VirtualMeetingFinderTableCell"
     
     /* ################################################################## */
     /**
      The table controller that "owns" this cell.
      */
     weak var myController: VMF_EmbeddedTableController?
     
     /* ################################################################## */
     /**
      The meeting instance associated with this.
      */
     var myMeeting: MeetingInstance? { didSet { setUpTextItems() } }
     
     /* ################################################################## */
     /**
      This has an image that denotes what type of meeting we have.
      */
     @IBOutlet weak var typeImage: UIImageView?
     
     /* ################################################################## */
     /**
      This is the meeting name.
      */
     @IBOutlet weak var nameLabel: UILabel?
     
     /* ################################################################## */
     /**
      This displays the weekday, start time, and end time.
      */
     @IBOutlet weak var timeAndDayLabel: UILabel?
     
     /* ################################################################## */
     /**
      The label that displays the timezone.
      */
     @IBOutlet weak var timeZoneLabel: UILabel?
     
     /* ################################################################## */
     /**
      The label that displays an in-progress message.
      */
     @IBOutlet weak var inProgressLabel: UILabel?
}

/* ###################################################################################################################################### */
// MARK: Base Class Overrides
/* ###################################################################################################################################### */
extension VMF_TableCell {
     /* ################################################################## */
     /**
      Called when the view is laid out.
      */
     override func layoutSubviews() {
          super.layoutSubviews()
          if myMeeting?.isMeetingInProgress() ?? false {
               borderColor = UIColor(named: "InProgress")
               borderWidth = 2
               cornerRadius = 8
          } else {
               borderColor = nil
               borderWidth = 0
               cornerRadius = 0
          }
     }
}

/* ###################################################################################################################################### */
// MARK: Callbacks
/* ###################################################################################################################################### */
extension VMF_TableCell {
     /* ################################################################## */
     /**
      Called when someone double-taps on the row.
      
      - parameter: ignored
      */
     @IBAction func doubleTapped(_: Any) {
          guard let myController = myController,
                let myMeeting = myMeeting
          else { return }
          setSelected(false, animated: false)
          myController.attendanceChanged(myMeeting)
     }
}

/* ###################################################################################################################################### */
// MARK: Instance Methods
/* ###################################################################################################################################### */
extension VMF_TableCell {
     /* ################################################################## */
     /**
      Sets all the items up. This is called when the meeting is changed.
      We can't wait for layout. This stuff needs to be done in advance.
      */
     func setUpTextItems() {
          guard let myController = myController,
                var meeting = myMeeting
          else { return }
          
          let inProgress = meeting.isMeetingInProgress()
          let startDate = meeting.getPreviousStartDate(isAdjusted: true)
          let startTime = startDate.localizedTime
          
          if meeting.iAttend {
               typeImage?.image = UIImage(systemName: "checkmark.square.fill")
               typeImage?.isAccessibilityElement = true
               typeImage?.accessibilityLabel = "SLUG-ACC-ATTEND-IMAGE-ON-LABEL".accessibilityLocalizedVariant
               typeImage?.accessibilityHint = "SLUG-ACC-ATTEND-IMAGE-ON-HINT".accessibilityLocalizedVariant
          } else {
               typeImage?.isAccessibilityElement = false
               typeImage?.image = nil
          }
          
          let meetingName = meeting.name
          let timeZoneString = myController.getMeetingTimeZone(meeting)
          let inProgressString = String(format: (Calendar.current.startOfDay(for: .now) > startDate ? "SLUG-IN-PROGRESS-YESTERDAY-FORMAT" : "SLUG-IN-PROGRESS-FORMAT").localizedVariant, startTime)
          
          nameLabel?.text = meetingName
          
          if !timeZoneString.isEmpty {
               timeZoneLabel?.isHidden = false
               timeZoneLabel?.text = timeZoneString
          } else {
               timeZoneLabel?.isHidden = true
          }
          
          if inProgress {
               inProgressLabel?.isHidden = false
               inProgressLabel?.text = inProgressString
          } else {
               inProgressLabel?.isHidden = true
          }
          
          let weekday = Calendar.current.weekdaySymbols[meeting.adjustedWeekday - 1]
          let nextStart = meeting.getNextStartDate(isAdjusted: true)
          
          if 0 < meeting.duration {
               timeAndDayLabel?.text = String(format: "SLUG-WEEKDAY-TIME-DURATION-FORMAT".localizedVariant, weekday, nextStart.localizedTime, nextStart.addingTimeInterval(meeting.duration).localizedTime)
          } else {
               timeAndDayLabel?.text = String(format: "SLUG-WEEKDAY-TIME-FORMAT".localizedVariant, weekday, nextStart.localizedTime)
          }
     }
}

/* ###################################################################################################################################### */
// MARK: - Embedded Table View Controller -
/* ###################################################################################################################################### */
/**
 This presents a simple view controller, with a table of meetings.
 */
class VMF_EmbeddedTableController: VMF_BaseViewController, VMF_EmbeddedTableControllerProtocol {
     /* ################################################################## */
     /**
      The storyboard ID, for instantiating this class
      */
     static let storyboardID = "VMF_EmbeddedTableController"
     
     /* ################################################################## */
     /**
      The background transparency, for alternating rows.
      */
     private static let _alternateRowOpacity = CGFloat(0.1)
     
     /* ################################################################## */
     /**
      The height of section headers, in display units.
      */
     private static let _sectionTitleHeightInDisplayUnits = CGFloat(30)
     
     /* ################################################################## */
     /**
      The segue ID, for inspecting individual meetings.
      */
     private static let _inspectMeetingSegueID = "inspect-meeting"
     
     /* ################################################################## */
     /**
      Used for the "Pull to Refresh"
      */
     private weak var _refreshControl: UIRefreshControl?
     
     /* ################################################################## */
     /**
      The controller that "owns" this instance.
      */
     weak var myController: VMF_MasterTableControllerProtocol?
     
     /* ################################################################## */
     /**
      If true (default), then we will not set up a refresh.
      */
     var noRefresh: Bool = true {
          didSet {
               if !noRefresh,
                  nil == _refreshControl {
                    let refresh = UIRefreshControl()
                    refresh.addTarget(self, action: #selector(refreshPulled), for: .valueChanged)
                    _refreshControl = refresh
                    valueTable?.refreshControl = refresh
               } else if noRefresh {
                    _refreshControl = nil
                    valueTable?.refreshControl = nil
               }
          }
     }
     
     /* ################################################################## */
     /**
      The time index for this table.
      */
     var timeIndex: Int = 0
     
     /* ################################################################## */
     /**
      The day index for this table.
      */
     var dayIndex: Int = 0
     
     /* ################################################################## */
     /**
      This handles the meeting collection for this.
      */
     var meetings: [MeetingInstance] = [] { didSet { valueTable?.reloadData() } }
     
     /* ################################################################## */
     /**
      This applies any filters to the list.
      */
     var filteredMeetings: [MeetingInstance] { meetings }
     
     /* ################################################################## */
     /**
      The table that shows the meetings for the current time.
      */
     @IBOutlet weak var valueTable: UITableView?
}

/* ###################################################################################################################################### */
// MARK: Base Class Overrides
/* ###################################################################################################################################### */
extension VMF_EmbeddedTableController {
     /* ################################################################## */
     /**
      Called when the view hierarchy has loaded.
      */
     override func viewDidLoad() {
          super.viewDidLoad()
          if !noRefresh {
               let refresh = UIRefreshControl()
               refresh.addTarget(self, action: #selector(refreshPulled), for: .valueChanged)
               _refreshControl = refresh
               valueTable?.refreshControl = refresh
          }
     }
     
     /* ################################################################## */
     /**
      Called just before the view appears
      
      - parameter inIsAnimated: True, if the appearance is animated.
      */
     override func viewWillAppear(_ inIsAnimated: Bool) {
          super.viewWillAppear(inIsAnimated)
          valueTable?.reloadData()
     }
     
     /* ################################################################## */
     /**
      Called just after the view appeared
      
      - parameter inIsAnimated: True, if the appearance is animated.
      */
     override func viewDidAppear(_ inIsAnimated: Bool) {
          super.viewDidAppear(inIsAnimated)
          myController?.tableDisplayController = self
          selectionHaptic()
          myController?.updateThermometer(self)
          myController?.setDayPicker()
          checkForUniversalLink()
     }

     /* ################################################################## */
     /**
      Called just before the view segues to another one.
      
      - parameter for: The segue instance.
      - parameter sender: Any associated data.
      */
     override func prepare(for inSegue: UIStoryboardSegue, sender inData: Any?) {
          if let destination = inSegue.destination as? VMF_MeetingInspectorViewController,
             let meetingInstance = inData as? MeetingInstance {
               destination.myController = self
               destination.meeting = meetingInstance
               hardImpactHaptic()
          }
     }
}

/* ###################################################################################################################################### */
// MARK: Instance Methods
/* ###################################################################################################################################### */
extension VMF_EmbeddedTableController {
     /* ################################################################## */
     /**
      This checks to see if we need to open a linked meeting.
      */
     func checkForUniversalLink() {
          if 0 < VMF_SceneDelegate.urlMeetingID,
             let meeting = VMF_AppDelegate.virtualService?.meetings.first(where: { $0.meeting.id == VMF_SceneDelegate.urlMeetingID })?.meeting {
               selectMeeting(meeting)
          }
          
          VMF_SceneDelegate.urlMeetingID = 0
     }
}

/* ###################################################################################################################################### */
// MARK: Callbacks
/* ###################################################################################################################################### */
extension VMF_EmbeddedTableController {
     /* ################################################################## */
     /**
      Called when attendance changes for a meeting.
      
      - parameter inMeeting: The meeting instance.
      */
     func attendanceChanged(_ inMeeting: MeetingInstance) {
          var mutableMeeting = inMeeting
          mutableMeeting.iAttend = !inMeeting.iAttend
          successHaptic()
          valueTable?.reloadData()
          myController?.setAttendance()   // This tells the "owner" to update its table and bar button.
     }
     
     /* ################################################################## */
     /**
      Called to show a meeting details page.
      
      - parameter inMeeting: The meeting instance.
      */
     func selectMeeting(_ inMeeting: MeetingInstance) {
          performSegue(withIdentifier: Self._inspectMeetingSegueID, sender: inMeeting)
     }
     
     /* ################################################################## */
     /**
      The refresh has been triggered.
      
      - parameter: Ignored (and can be omitted).
      */
     @objc func refreshPulled(_: Any) {
          _refreshControl?.endRefreshing()
          myController?.refreshCalled {
               self.valueTable?.reloadData()
               if !self.filteredMeetings.isEmpty {
                    self.valueTable?.scrollToRow(at: IndexPath(row: 0, section: 0), at: .top, animated: false)
               }
          }
     }
}

/* ###################################################################################################################################### */
// MARK: UITableViewDataSource Conformance
/* ###################################################################################################################################### */
extension VMF_EmbeddedTableController: UITableViewDataSource {
     /* ################################################################## */
     /**
      - parameter: The table view (ignored)
      - parameter numberOfRowsInSection: The 0-based section index.
      - returns: The number of meetings to display.
      */
     func tableView(_: UITableView, numberOfRowsInSection : Int) -> Int { filteredMeetings.count }
     
     /* ################################################################## */
     /**
      - parameter inTableView: The table view
      - parameter numberOfRowsInSection: The index path of the cell we want.
      */
     func tableView(_ inTableView: UITableView, cellForRowAt inIndexPath: IndexPath) -> UITableViewCell {
          guard let ret = inTableView.dequeueReusableCell(withIdentifier: VMF_TableCell.reuseID) as? VMF_TableCell else { return UITableViewCell() }
          
          ret.myController = self
          ret.backgroundColor = (0 == inIndexPath.row % 2) ? UIColor.label.withAlphaComponent(Self._alternateRowOpacity) : .clear
          ret.myMeeting = filteredMeetings[inIndexPath.row]
          
          return ret
     }
}

/* ###################################################################################################################################### */
// MARK: UITableViewDelegate Conformance
/* ###################################################################################################################################### */
extension VMF_EmbeddedTableController: UITableViewDelegate {
     /* ################################################################## */
     /**
      Called just before the selection. We use this to trigger a haptic, and bring in the meeting.
      - parameter: The table view (ignored)
      - parameter willSelectRowAt: The index path of the row
      - returns: The index path (always)
      */
     func tableView(_: UITableView, willSelectRowAt inIndexPath: IndexPath) -> IndexPath? {
          selectionHaptic()
          selectMeeting(filteredMeetings[inIndexPath.row])
          return inIndexPath
     }
}

