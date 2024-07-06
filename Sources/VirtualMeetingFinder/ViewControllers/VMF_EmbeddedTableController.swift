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
 Protocol for owners
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
// MARK: - Protocol for "Owners" of This Class -
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
// MARK: - Protocol for "Owners" of This Class -
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
    func updateThermometer(_ inTablePage: VMF_EmbeddedTableControllerProtocol? = nil) { }
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
     This has an image that denotes what type of meeting we have.
     */
    @IBOutlet weak var typeImage: UIImageView?

    /* ################################################################## */
    /**
     This is the meeting name.
     */
    @IBOutlet weak var nameLabel: UILabel?

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
            } else {
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
    var meetings: [MeetingInstance] = [] { didSet { valueTable?.reloadData() }}

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
     Called just after the view appeared
     
     - parameter inIsAnimated: True, if the appearance is animated.
     */
    override func viewDidAppear(_ inIsAnimated: Bool) {
        super.viewDidAppear(inIsAnimated)
        myController?.tableDisplayController = self
        valueTable?.reloadData()
    }
    
    /* ################################################################## */
    /**
     Called when the view has laid out its subviews.
     */
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        valueTable?.reloadData()
        myController?.updateThermometer(self)
    }
    
    /* ################################################################## */
    /**
     Called just before the view segues to another one.
     
     - parameter for: The segue instance.
     - parameter sender: Any associated data.
     */
    override func prepare(for inSegue: UIStoryboardSegue, sender inData: Any?) {
        if let destination = inSegue.destination as? VMF_MeetingViewController,
           let meetingInstance = inData as? MeetingInstance {
            destination.myController = self
            destination.meeting = meetingInstance
        }
    }
}

/* ###################################################################################################################################### */
// MARK: Callbacks
/* ###################################################################################################################################### */
extension VMF_EmbeddedTableController {
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
    func tableView(_: UITableView, numberOfRowsInSection : Int) -> Int { meetings.count }
    
    /* ################################################################## */
    /**
     - parameter inTableView: The table view
     - parameter numberOfRowsInSection: The index path of the cell we want.
     */
    func tableView(_ inTableView: UITableView, cellForRowAt inIndexPath: IndexPath) -> UITableViewCell {
        guard let ret = inTableView.dequeueReusableCell(withIdentifier: VMF_TableCell.reuseID, for: inIndexPath) as? VMF_TableCell else { return UITableViewCell() }
        
        let backgroundColorToUse: UIColor? = (1 == inIndexPath.row % 2) ? UIColor.label.withAlphaComponent(Self._alternateRowOpacity) : .clear

        var meeting = meetings[inIndexPath.row]
    
        let inProgress = meeting.isMeetingInProgress()
        let startDate = meeting.getPreviousStartDate(isAdjusted: true)
        let startTime = startDate.localizedTime
        
        if meeting.iAttend {
            ret.typeImage?.image = UIImage(systemName: "checkmark.square.fill")
        } else {
            ret.typeImage?.image = nil
        }

        let meetingName = meeting.name
        let timeZoneString = getMeetingTimeZone(meeting)
        let inProgressString = String(format: (Calendar.current.startOfDay(for: .now) > startDate ? "SLUG-IN-PROGRESS-YESTERDAY-FORMAT" : "SLUG-IN-PROGRESS-FORMAT").localizedVariant, startTime)
        
        ret.nameLabel?.text = meetingName
        
        if !timeZoneString.isEmpty {
            ret.timeZoneLabel?.isHidden = false
            ret.timeZoneLabel?.text = timeZoneString
        } else {
            ret.timeZoneLabel?.isHidden = true
        }
        
        if inProgress,
           !inProgressString.isEmpty {
            ret.inProgressLabel?.isHidden = false
            ret.inProgressLabel?.text = inProgressString
        } else {
            ret.inProgressLabel?.isHidden = true
        }
        
        if inProgress {
            ret.borderColor = UIColor(named: "InProgress")
            ret.borderWidth = 2
            ret.cornerRadius = 8
        } else {
            ret.borderColor = nil
            ret.borderWidth = 0
            ret.cornerRadius = 0
        }
        
        ret.backgroundColor = backgroundColorToUse

        if 0 == dayIndex,
           0 == timeIndex,
           myController is VMF_AttendanceViewController {
            ret.timeAndDayLabel?.isHidden = false
            let weekday = Calendar.current.weekdaySymbols[meeting.adjustedWeekday - 1]
            let startTime = meeting.getNextStartDate(isAdjusted: true)

            if 0 < meeting.duration {
                ret.timeAndDayLabel?.text = String(format: "SLUG-WEEKDAY-TIME-DURATION-FORMAT".localizedVariant, weekday, startTime.localizedTime, startTime.addingTimeInterval(meeting.duration).localizedTime)
            } else {
                ret.timeAndDayLabel?.text = String(format: "SLUG-WEEKDAY-TIME-FORMAT".localizedVariant, weekday, startTime.localizedTime)
            }
        } else {
            ret.timeAndDayLabel?.isHidden = true
        }
        
        return ret
    }
}

/* ###################################################################################################################################### */
// MARK: UITableViewDelegate Conformance
/* ###################################################################################################################################### */
extension VMF_EmbeddedTableController: UITableViewDelegate {
    /* ################################################################## */
    /**
     Called when a cell is selected. We will use this to open the user viewer.
     
     - parameter: The table view (ignored)
     - parameter willSelectRowAt: The index path of the cell we are selecting.
     - returns: nil (all the time).
     */
    func tableView(_: UITableView, willSelectRowAt inIndexPath: IndexPath) -> IndexPath? {
        let meeting = meetings[inIndexPath.row]
        selectMeeting(meeting)
        return nil
    }
}
