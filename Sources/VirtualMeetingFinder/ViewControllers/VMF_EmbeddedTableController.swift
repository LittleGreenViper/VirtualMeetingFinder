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

    /* ################################################################## */
    /**
     This converts a 1 == Sun format into a localized weekday index (1 ... 7)
     
     - parameter: An integer (1 = Sunday), with the unlocalized index.
     - returns: The 1-based weekday index for the local system.
     */
    func mapWeekday(_ inWeekdayIndex: Int) -> Int

    /* ################################################################## */
    /**
     This converts the selected localized weekday into the 1 == Sun format needed for the meeting data.
     
     - parameter: An integer (1 -> 7), with the localized weekday.
     - returns: The 1-based weekday index for 1 = Sunday
     */
    func unMapWeekday(_ inWeekdayIndex: Int) -> Int

    /* ################################################################## */
    /**
     This returns a string, with the localized timezone name for the meeting.
     It is not set, if the timezone is ours.
     
     - parameter inMeeting: The meeting instance.
     - returns: The timezone string.
     */
    func getMeetingTimeZone(_ inMeeting: MeetingInstance) -> String
}

/* ###################################################################################################################################### */
// MARK: Defaults
/* ###################################################################################################################################### */
extension VMF_BaseProtocol {
    /* ################################################################## */
    /**
     Default is nil
     */
    var myController: (any VMF_MasterTableControllerProtocol)? { nil }
    
    /* ################################################################## */
    /**
     This converts a 1 == Sun format into a localized weekday index (1 ... 7)
     
     - parameter: An integer (1 = Sunday), with the unlocalized index.
     - returns: The 1-based weekday index for the local system.
     */
    func mapWeekday(_ inWeekdayIndex: Int) -> Int {
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
class VMF_EmbeddedTableController: VMF_TabBaseViewController, VMF_EmbeddedTableControllerProtocol {
    /* ################################################################## */
    /**
     The storyboard ID, for instantiating this class
     */
    static let storyboardID = "VMF_EmbeddedTableController"
    
    /* ################################################################## */
    /**
     The background transparency, for alternating rows.
     */
    private static let _alternateRowOpacity = CGFloat(0.05)

    /* ################################################################## */
    /**
     The background transparency, for alternating rows (In progress).
     */
    private static let _alternateRowOpacityIP = CGFloat(0.5)

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
    var meetings: [MeetingInstance] = []

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
        let refresh = UIRefreshControl()
        refresh.addTarget(self, action: #selector(refreshPulled), for: .valueChanged)
        _refreshControl = refresh
        valueTable?.refreshControl = refresh
    }
    
    /* ################################################################## */
    /**
     Called just after the view appeared
     
     - parameter inIsAnimated: True, if the appearance is animated.
     */
    override func viewDidAppear(_ inIsAnimated: Bool) {
        super.viewDidAppear(inIsAnimated)
        myController?.tableDisplayController = self
    }
    
    /* ################################################################## */
    /**
     Called when the view has laid out its subviews.
     */
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        valueTable?.reloadData()
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
        myController?.refreshCalled { self.valueTable?.reloadData() }
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
        
        var backgroundColorToUse: UIColor? = (1 == inIndexPath.row % 2) ? UIColor.label.withAlphaComponent(Self._alternateRowOpacity) : .clear

        var meeting = meetings[inIndexPath.row]
    
        let inProgress = meeting.isMeetingInProgress()
        let startTime = meeting.getPreviousStartDate(isAdjusted: true).localizedTime

        let meetingName = meeting.name
        let timeZoneString = getMeetingTimeZone(meeting)
        let inProgressString = String(format: "SLUG-IN-PROGRESS-FORMAT".localizedVariant, startTime)
        
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
            backgroundColorToUse = UIColor(named: "InProgress")
            
            if (0 == inIndexPath.row % 2) {
                backgroundColorToUse = backgroundColorToUse?.withAlphaComponent(Self._alternateRowOpacityIP)
            }
        }
        
        ret.typeImage?.image = meeting.sortableMeetingType.image
        
        ret.backgroundColor = backgroundColorToUse

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
