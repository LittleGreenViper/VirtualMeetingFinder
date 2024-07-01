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
// MARK: - Protocol for "Owners" of This Class -
/* ###################################################################################################################################### */
/**
 Protocol for embedded tables.
 */
protocol VMF_EmbeddedTableControllerProtocol: NSObjectProtocol {
    /* ################################################################## */
    /**
     This is an alias for the tuple type we use for time-mapped meeting data.
     */
    typealias MappedSet = (time: String, meetings: [MeetingInstance])

    /* ################################################################## */
    /**
     The controller that "owns" this instance.
     */
    var myController: VMF_MasterTableController? { get set }
    
    /* ################################################################## */
    /**
     Contains the search text filter.
     */
    var searchText: String { get set }
    
    /* ################################################################## */
    /**
     Contains the weekday selected (0 - 7, with 1 => Sunday, 7 => Saturday, and 0 in-progress).
     */
    var weekday: Int { get set }
    
    /* ################################################################## */
    /**
     Contains the time selected. This is an index of times (MappedSet times).
     */
    var timeIndex: Int { get set }
    
    /* ################################################################## */
    /**
     This handles the server data.
     */
    var virtualService: SwiftBMLSDK_MeetingLocalTimezoneCollection? { get set }
    
    /* ################################################################## */
    /**
     This is an array of the time-mapped meeting data.
     */
    var mappedDataset: [[MappedSet]] { get set }

    /* ################################################################## */
    /**
     This is set to true, if we are in name search mode.
     */
    var isNameSearchMode: Bool { get set }
}

/* ###################################################################################################################################### */
// MARK: - Protocol for "Owners" of This Class -
/* ###################################################################################################################################### */
/**
 Protocol for owners
 */
protocol VMF_MasterTableController: NSObjectProtocol {
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
    /* ################################################################################################################################## */
    // MARK: Meeting Table Data Format
    /* ################################################################################################################################## */
    typealias TableFood = (sectionTitle: String, meetings: [MeetingInstance])
    
    /* ################################################################################################################################## */
    // MARK: Meeting Table Sort Types
    /* ################################################################################################################################## */
    /**
     This is the main view controller for the weekday/time selector tab.
     */
    enum SortType: Int {
        /* ############################################################## */
        /**
         The sort is via the timezone name.
         */
        case timeZone = 0
        
        /* ############################################################## */
        /**
         The sort is via the meeting type.
         */
        case type = 1
        
        /* ############################################################## */
        /**
         The sort is via the meeting name.
         */
        case name = 2
        
        /* ############################################################## */
        /**
         The sort is via the meeting start time.
         */
        case time = 3
    }
    
    /* ################################################################## */
    /**
     How many seconds are in a 24-hour day.
     */
    fileprivate static let _oneDayInSeconds = TimeInterval(86400)
    
    /* ################################################################## */
    /**
     The image to use for our ascending sort.
     */
    private class var _sortButtonASCImage: UIImage? {
        guard let image = _sortButtonDESCImage else { return nil }
        
        UIGraphicsBeginImageContextWithOptions(image.size, false, image.scale)
        defer { UIGraphicsEndImageContext() }

        guard let context = UIGraphicsGetCurrentContext() else { return nil }
        
        context.translateBy(x: image.size.width/2, y: image.size.height/2)
        context.scaleBy(x: 1.0, y: -1.0)
        context.translateBy(x: -image.size.width/2, y: -image.size.height/2)
        
        image.draw(in: CGRect(x: 0, y: 0, width: image.size.width, height: image.size.height))
        
        let newImage = UIGraphicsGetImageFromCurrentImageContext()
        
        return newImage?.withRenderingMode(.alwaysTemplate)
    }
    
    /* ################################################################## */
    /**
     The image to use for our ascending sort.
     */
    private class var _sortButtonDESCImage: UIImage? {
        UIImage(systemName: "line.3.horizontal.decrease.circle")?.applyingSymbolConfiguration(UIImage.SymbolConfiguration(scale: .large))
    }
    
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
     This handles the meeting collection for this.
     */
    private var _meetings: [MeetingInstance] = []

    /* ################################################################## */
    /**
     This is an array of the time-mapped meeting data.
     */
    var mappedDataset = [[MappedSet]]()

    /* ################################################################## */
    /**
     This is set to true, if we are in name search mode.
     */
    var isNameSearchMode: Bool = false
    
    /* ################################################################## */
    /**
     This is set to true, if the "now" segment is selected.
     */
    private var _wasNow = false
    
    /* ################################################################## */
    /**
     This is set to false, once we have rendered, the first time.
     */
    private var _firstTime = true
    
    /* ################################################################## */
    /**
     This is set to true, if the sort direction is ascending.
     */
    private var _isSortAsc = true { didSet { setSortButton() }}
    
    /* ################################################################## */
    /**
     Used for the "Pull to Refresh"
     */
    private weak var _refreshControl: UIRefreshControl?
    
    /* ################################################################## */
    /**
     Cached table data.
     */
    private var _cachedTableFood: [(sectionTitle: String, meetings: [MeetingInstance])] = []
    
    /* ################################################################## */
    /**
     Cached table data (for when in Search Mode).
     */
    private var _cachedSearchMeetings: [MeetingInstance] = []
    
    /* ################################################################## */
    /**
     The controller that "owns" this instance.
     */
    weak var myController: VMF_MasterTableController?

    /* ################################################################## */
    /**
     Contains the search text filter.
     */
    var searchText: String = "" { didSet { } }
    
    /* ################################################################## */
    /**
     This handles the server data.
     */
    var virtualService: SwiftBMLSDK_MeetingLocalTimezoneCollection? { didSet { mapData() } }

    /* ################################################################## */
    /**
     Returns meetings with names that begin with the text entered.
     */
    var searchedMeetings: [MeetingInstance] {
        guard !searchText.isEmpty else { return _cachedSearchMeetings }
        let lcText = searchText.lowercased()
        return (_cachedSearchMeetings.filter { $0.name.lowercased().beginsWith(lcText) })
    }
    
    /* ################################################################## */
    /**
     Contains the weekday selected (0 - 7, with 1 => Sunday, 7 => Saturday, and 0 in-progress).
     */
    var weekday: Int = 0
    
    /* ################################################################## */
    /**
     Contains the time selected. This is an index of times (MappedSet times).
     */
    var timeIndex: Int = 0

    /* ################################################################## */
    /**
     This contains all the visible items.
     */
    @IBOutlet weak var mainContainerView: UIView?

    /* ################################################################## */
    /**
     The table that shows the meetings for the current time.
     */
    @IBOutlet weak var valueTable: UITableView?

    /* ################################################################## */
    /**
     The segmented switch that sets the sort
     */
    @IBOutlet weak var sortSegmentedSwitch: UISegmentedControl?
    
    /* ################################################################## */
    /**
     The container for the sort items.
     */
    @IBOutlet weak var sortContainer: UIView?
    
    /* ################################################################## */
    /**
     The label for the sort switch.
     */
    @IBOutlet weak var sortLabel: UILabel?
    
    /* ################################################################## */
    /**
     The ascending/descending sort button.
     */
    @IBOutlet weak var sortButton: UIButton?
}

/* ###################################################################################################################################### */
// MARK: Computed Properties
/* ###################################################################################################################################### */
extension VMF_EmbeddedTableController {
    /* ################################################################## */
    /**
     The data for display in the table.
     
     It is arranged in sections, with the "meetings" member, containing the row data.
     */
    var tableFood: [(sectionTitle: String, meetings: [MeetingInstance])] {
        guard _cachedTableFood.isEmpty else { return _cachedTableFood }
        
        let currentIntegerTime = Calendar.current.component(.hour, from: .now) * 100 + Calendar.current.component(.minute, from: .now)
        guard !isNameSearchMode else { return [(sectionTitle: "", meetings: searchedMeetings)] }
        
        let meetings = _meetings.sorted { a, b in
            var ret = false
            
            let tzA = Self.getMeetingTimeZone(a)
            let tzB = Self.getMeetingTimeZone(b)
            var aTime = a.adjustedIntegerStartTime
            var bTime = b.adjustedIntegerStartTime

            if aTime > currentIntegerTime {
                aTime -= 2400
            }

            if bTime > currentIntegerTime {
                bTime -= 2400
            }

            if let sortType = sortSegmentedSwitch?.selectedSegmentIndex,
               let sortBy = SortType(rawValue: sortType) {
                switch sortBy {
                case .timeZone:
                    ret = tzA < tzB ? true :
                        tzA != tzB ? false :
                            a.sortableMeetingType < b.sortableMeetingType ? true :
                                a.sortableMeetingType != b.sortableMeetingType ? false :
                                    aTime < bTime ? true :
                                        aTime != bTime ? false :
                                            a.name < b.name

                case .type:
                    ret = a.sortableMeetingType < b.sortableMeetingType ? true :
                        a.sortableMeetingType != b.sortableMeetingType ? false :
                            tzA < tzB ? true :
                                tzA != tzB ? false :
                                    aTime < bTime ? true :
                                        aTime != bTime ? false :
                                            a.name < b.name
                    
                case .name:
                    ret = a.name < b.name ? true :
                        a.name != b.name ? false :
                            tzA < tzB ? true :
                                tzA != tzB ? false :
                                    aTime < bTime ? true :
                                        aTime != bTime ? false :
                                            a.sortableMeetingType < b.sortableMeetingType

                case .time:
                    ret = aTime < bTime ? true :
                            aTime != bTime ? false :
                                tzA < tzB ? true :
                                    tzA != tzB ? false :
                                        a.sortableMeetingType < b.sortableMeetingType ? true :
                                            a.sortableMeetingType != b.sortableMeetingType ? false :
                                                a.name < b.name
                }
            }
            
            return self._isSortAsc ? ret : !ret
        }
        
        _cachedTableFood = [(sectionTitle: "", meetings: meetings)]
        
        return _cachedTableFood
    }
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
        valueTable?.sectionHeaderTopPadding = CGFloat(0)

        for index in (0..<(sortSegmentedSwitch?.numberOfSegments ?? 0)) {
            sortSegmentedSwitch?.setTitle(sortSegmentedSwitch?.titleForSegment(at: index)?.localizedVariant, forSegmentAt: index)
        }
    }
    
    /* ################################################################## */
    /**
     Called just before the view is to appear.
     
     - parameter inIsAnimated: True, if the appearance is animated.
     */
    override func viewWillAppear(_ inIsAnimated: Bool) {
        super.viewWillAppear(inIsAnimated)
        _wasNow = false
        valueTable?.reloadData()
        myController?.tableDisplayController = self
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
// MARK: Static Functions
/* ###################################################################################################################################### */
extension VMF_EmbeddedTableController {
    /* ################################################################## */
    /**
     This converts a 1 == Sun format into a localized weekday index (1 ... 7)
     
     - parameter: An integer (1 = Sunday), with the unlocalized index.
     - returns: The 1-based weekday index for the local system.
     */
    static func mapWeekday(_ inWeekdayIndex: Int) -> Int {
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
    static func unMapWeekday(_ inWeekdayIndex: Int) -> Int {
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
    static func getMeetingTimeZone(_ inMeeting: MeetingInstance) -> String {
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
// MARK: Instance Methods
/* ###################################################################################################################################### */
extension VMF_EmbeddedTableController {
    /* ################################################################## */
    /**
     */
    func setUpTable() {
        
    }
    
    /* ################################################################## */
    /**
     */
    func setUpSortHeader() {
        
    }
    
    /* ################################################################## */
    /**
     This maps the times for the selected day.
     */
    func mapData() {
        mappedDataset = []
        
        guard let virtualService = virtualService else { return }

        var daySet = [MappedSet]()
        
        var meetings = [MeetingInstance]()

        for day in 1...7 {
            meetings = virtualService.meetings.compactMap {
                let weekday = Calendar.current.component(.weekday, from: $0.nextDate)
                return weekday == day ? $0.meeting : nil
            }
            
            var times = [Int: [MeetingInstance]]()
            
            meetings.forEach {
                let time = $0.adjustedIntegerStartTime
                if nil == times[time] {
                    times[time] = [$0]
                } else {
                    times[time]?.append($0)
                }
            }
            
            daySet = []
            
            for timeInst in times.keys.sorted() {
                let meetings = meetings.filter { $0.adjustedIntegerStartTime == timeInst }
                let string = (1200 == timeInst) ? "SLUG-NOON-TIME".localizedVariant : (2359 == timeInst) ? "SLUG-MIDNIGHT-TIME".localizedVariant : meetings[0].timeString
                daySet.append(MappedSet(time: string, meetings: meetings))
            }
            
            mappedDataset.append(daySet)
        }
    }
    
    /* ################################################################## */
    /**
     Called to set up the sort button.
     */
    func setSortButton() {
        guard let tintColor = view?.tintColor else { return }
        
        let image = _isSortAsc ? Self._sortButtonASCImage : Self._sortButtonDESCImage
        
        sortButton?.setImage(image?.withTintColor(tintColor), for: .normal)
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
        
    }
    
    /* ################################################################## */
    /**
     The segmented switch that sets the sort was changed
     
     - parameter: Ignored (and can be omitted).
     */
    @IBAction func sortChanged(_: Any! = nil) {
        _cachedTableFood = []
        valueTable?.reloadData()
    }
    
    /* ################################################################## */
    /**
     The sort button was hit
     
     - parameter: Ignored
     */
    @IBAction func sortButtonHit(_: Any) {
        _isSortAsc = !_isSortAsc
        sortChanged()
    }
    
    /* ################################################################## */
    /**
     The search text was changed.
     
     - parameter inTextField: The search text field (ignored)
     */
    @IBAction func searchTextChanged(_: UITextField) {
        guard isNameSearchMode else { return }
        valueTable?.reloadData()
    }
}

/* ###################################################################################################################################### */
// MARK: UITableViewDataSource Conformance
/* ###################################################################################################################################### */
extension VMF_EmbeddedTableController: UITableViewDataSource {
    /* ################################################################## */
    /**
     Returns the number of sections to display.
     
     - parameter in: The table view (ignored)
     - returns: The number of sections to display.
     */
    func numberOfSections(in: UITableView) -> Int {
        if tableFood.isEmpty {
            sortContainer?.isHidden = true
        }
        return tableFood.count
    }
    
    /* ################################################################## */
    /**
     - parameter: The table view (ignored)
     - parameter numberOfRowsInSection: The 0-based section index.
     - returns: The number of meetings to display.
     */
    func tableView(_: UITableView, numberOfRowsInSection inSectionIndex: Int) -> Int {
        let ret = tableFood[inSectionIndex].meetings.count
        sortContainer?.isHidden = isNameSearchMode || 1 >= ret
        
        return ret
    }
    
    /* ################################################################## */
    /**
     - parameter inTableView: The table view
     - parameter numberOfRowsInSection: The index path of the cell we want.
     */
    func tableView(_ inTableView: UITableView, cellForRowAt inIndexPath: IndexPath) -> UITableViewCell {
        guard let ret = inTableView.dequeueReusableCell(withIdentifier: VMF_TableCell.reuseID, for: inIndexPath) as? VMF_TableCell else { return UITableViewCell() }
        
        var backgroundColorToUse: UIColor? = (1 == inIndexPath.row % 2) ? UIColor.label.withAlphaComponent(Self._alternateRowOpacity) : .clear

        var meeting = tableFood[inIndexPath.section].meetings[inIndexPath.row]
    
        let inProgress = meeting.isMeetingInProgress()
        let startTime = meeting.getPreviousStartDate(isAdjusted: true).localizedTime

        let meetingName = meeting.name
        let timeZoneString = Self.getMeetingTimeZone(meeting)
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
        let meeting = tableFood[inIndexPath.section].meetings[inIndexPath.row]
        selectMeeting(meeting)
        return nil
    }
    
    /* ################################################################## */
    /**
     Returns the height for the section header, in display units.
     
     - parameter: The table view (ignored)
     - parameter heightForHeaderInSection: The section we want the height for.
     - returns: 0, if there is only one section, or the height, if there are more than one, and the section has a string.
     */
    func tableView(_: UITableView, heightForHeaderInSection inSection: Int) -> CGFloat { (1 < tableFood.count && !tableFood[inSection].sectionTitle.isEmpty) ? Self._sectionTitleHeightInDisplayUnits : 0 }
    
    /* ################################################################## */
    /**
     Returns the displayed header for the given section.
     
     - parameter: The table view (ignored)
     - parameter viewForHeaderInSection: The 0-based section index.
     - returns: The header view (a button).
     */
    func tableView(_: UITableView, viewForHeaderInSection inSection: Int) -> UIView? {
        guard 1 < tableFood.count else { return nil }
        let title = tableFood[inSection].sectionTitle
        
        let ret = UILabel()
        
        ret.text = title
        return ret
    }
}
