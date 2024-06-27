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
// MARK: - Abstraction for the Meeting Type -
/* ###################################################################################################################################### */
public typealias MeetingInstance = SwiftBMLSDK_Parser.Meeting

/* ###################################################################### */
/**
 This adds various functionality to the String class.
 */
public extension String {
    /* ################################################################## */
    /**
     This tests a string to see if a given substring is present at the start.
     
     - parameter inSubstring: The substring to test.
     
     - returns: true, if the string begins with the given substring.
     */
    func beginsWith (_ inSubstring: String) -> Bool {
        var ret: Bool = false
        if let range = self.range(of: inSubstring) {
            ret = (range.lowerBound == self.startIndex)
        }
        return ret
    }
}

/* ###################################################################################################################################### */
// MARK: - Additional Function for Meetings -
/* ###################################################################################################################################### */
extension MeetingInstance {
    /* ################################################################## */
    /**
     This allows us to return a string for the meeting time.
     */
    var timeString: String {
        var mutableSelf = self
        let nextDate = mutableSelf.getNextStartDate(isAdjusted: true)
        let formatter = DateFormatter()
        formatter.dateFormat = .none
        formatter.timeStyle = .short
        return formatter.string(from: nextDate)
    }
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
// MARK: - Special Slider Setup for Times -
/* ###################################################################################################################################### */
/**
 This is a conglomerate tool, containing a slider, a stepper, a label, and a button.
 
 It works as a single panel in the UI, and allows the user to select a time slot for meetings.
 */
class VMF_TimeSlider: UIControl {
    /* ################################################################## */
    /**
     The image to use for our thumb.
     */
    private static let _thumbImage = UIImage(systemName: "arrowtriangle.down.fill")?.applyingSymbolConfiguration(UIImage.SymbolConfiguration(scale: .large))

    /* ################################################################## */
    /**
     This just contains the set of meetings to be used by this slider.
     */
    var meetings = [VMF_MainSearchViewController.MappedSet]() {
        didSet {
            sliderControl?.minimumValue = 0
            sliderControl?.maximumValue = max(0, Float(meetings.count - 1))
            setNeedsLayout()
        }
    }
    
    /* ################################################################## */
    /**
     This is the container for the lower part of the slider aggregate.
     */
    weak var container: UIView?
    
    /* ################################################################## */
    /**
     This is the actual slider control.
     */
    weak var sliderControl: UISlider?

    /* ################################################################## */
    /**
     The label that displays the currently selected time slot.
     */
    weak var valueLabel: UILabel?
    
    /* ################################################################## */
    /**
     The stepper, to step through the values, one by one.
     */
    weak var valueStepper: UIStepper?
    
    /* ################################################################## */
    /**
     A button to reset to today/now.
     */
    weak var resetButton: UIButton?

    /* ################################################################## */
    /**
     This is the main view controller that "owns" this instance.
     */
    @IBOutlet weak var controller: VMF_MainSearchViewController?
}

/* ###################################################################################################################################### */
// MARK: Computed Properties
/* ###################################################################################################################################### */
extension VMF_TimeSlider {
    /* ################################################################## */
    /**
     This is the subset of the meeting set that correspond to the selected time.
     */
    var selectedMeetings: [MeetingInstance] {
        guard let value = sliderControl?.value,
              !meetings.isEmpty
        else { return [] }
        
        let intValue = max(0, min((meetings.count - 1), Int(round(value))))
        
        return meetings[intValue].meetings
    }
}

/* ###################################################################################################################################### */
// MARK: Base Class Overrides
/* ###################################################################################################################################### */
extension VMF_TimeSlider {
    /* ################################################################## */
    /**
     Called when the control is being laid out.
     */
    override func layoutSubviews() {
        super.layoutSubviews()
        
        if nil == sliderControl,
           let thumbImage = Self._thumbImage {
            let tempSlider = UISlider()
            tempSlider.setThumbImage(thumbImage, for: .normal)
            tempSlider.maximumTrackTintColor = .systemGray4
            tempSlider.minimumTrackTintColor = .systemGray4
            tempSlider.addTarget(self, action: #selector(sliderChanged), for: .valueChanged)
            tempSlider.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(sliderTapped)))
            addSubview(tempSlider)
            sliderControl = tempSlider
            tempSlider.translatesAutoresizingMaskIntoConstraints = false
            tempSlider.topAnchor.constraint(equalTo: topAnchor).isActive = true
            tempSlider.leftAnchor.constraint(equalTo: leftAnchor).isActive = true
            tempSlider.rightAnchor.constraint(equalTo: rightAnchor).isActive = true
        }
        
        sliderControl?.minimumValue = 0
        sliderControl?.maximumValue = max(0, Float(meetings.count - 1))
        sliderControl?.value = Float(max(0, min((meetings.count - 1), Int(round(sliderControl?.value ?? 0)))))

        addValueLabel()
        
        sliderControl?.sendActions(for: .valueChanged)
    }
}

/* ###################################################################################################################################### */
// MARK: Instance Methods
/* ###################################################################################################################################### */
extension VMF_TimeSlider {
    /* ################################################################## */
    /**
     This adds the value label and stepper.
     */
    func addValueLabel() {
        if nil == container,
           let sliderControl = sliderControl,
           !meetings.isEmpty {
            let containerView = UIView()
            addSubview(containerView)
            container = containerView
            containerView.translatesAutoresizingMaskIntoConstraints = false
            containerView.topAnchor.constraint(greaterThanOrEqualTo: sliderControl.bottomAnchor, constant: 4).isActive = true
            containerView.bottomAnchor.constraint(equalTo: bottomAnchor).isActive = true
            containerView.leftAnchor.constraint(equalTo: leftAnchor).isActive = true
            containerView.rightAnchor.constraint(equalTo: rightAnchor).isActive = true

            let label = UILabel()
            label.textAlignment = .center
            label.font = .systemFont(ofSize: 15)
            containerView.addSubview(label)
            valueLabel = label
            label.translatesAutoresizingMaskIntoConstraints = false
            label.centerXAnchor.constraint(equalTo: containerView.centerXAnchor).isActive = true
            label.setContentHuggingPriority(.required, for: .horizontal)

            let stepper = UIStepper()
            stepper.autorepeat = true
            stepper.minimumValue = Double(sliderControl.minimumValue)
            stepper.maximumValue = Double(sliderControl.maximumValue)
            stepper.stepValue = (stepper.maximumValue - stepper.minimumValue) / Double(meetings.count)
            containerView.addSubview(stepper)
            valueStepper = stepper
            stepper.translatesAutoresizingMaskIntoConstraints = false
            stepper.addTarget(self, action: #selector(stepperChanged), for: .valueChanged)
            stepper.leftAnchor.constraint(greaterThanOrEqualTo: label.rightAnchor, constant: 4).isActive = true
            stepper.rightAnchor.constraint(equalTo: containerView.rightAnchor).isActive = true
            stepper.centerYAnchor.constraint(equalTo: label.centerYAnchor).isActive = true
            stepper.bottomAnchor.constraint(equalTo: containerView.bottomAnchor).isActive = true

            let reset = UIButton(type: .roundedRect)
            reset.addTarget(self, action: #selector(resetButtonHit), for: .touchUpInside)
            reset.setTitle("SLUG-RESET".localizedVariant, for: .normal)
            containerView.addSubview(reset)
            resetButton = reset
            reset.translatesAutoresizingMaskIntoConstraints = false
            reset.leftAnchor.constraint(equalTo: containerView.leftAnchor, constant: 8).isActive = true
            reset.rightAnchor.constraint(lessThanOrEqualTo: label.leftAnchor).isActive = true
            reset.centerYAnchor.constraint(equalTo: label.centerYAnchor).isActive = true
        } else if meetings.isEmpty {
            container?.removeFromSuperview()
            container = nil
        }
    }
}

/* ###################################################################################################################################### */
// MARK: Callbacks
/* ###################################################################################################################################### */
extension VMF_TimeSlider {
    /* ################################################################## */
    /**
     Called whenever the slider control changes.
     
     - parameter inSlider: The slider control that changed.
     */
    @objc func sliderChanged(_ inSlider: UISlider) {
        let value = inSlider.value
        let intValue = max(0, min((meetings.count - 1), Int(round(value))))
        inSlider.value = Float(intValue)
        valueStepper?.value = Double(intValue)
        valueLabel?.text = meetings[intValue].time
        controller?.timeSliderChanged(intValue, slider: self)
    }
    
    /* ################################################################## */
    /**
     Called whenever the stepper control changes.
     
     - parameter inSlider: The slider control that changed.
     */
    @objc func stepperChanged(_ inStepper: UIStepper) {
        let value = inStepper.value
        let intValue = max(0, min((meetings.count - 1), Int(round(value))))
        sliderControl?.value = Float(intValue)
        sliderControl?.sendActions(for: .valueChanged)
    }
    
    /* ################################################################## */
    /**
     Called whenever the reset button is hit
     
     - parameter: ignored
     */
    @objc func resetButtonHit(_: Any) {
        controller?.setToNow()
    }
    
    /* ################################################################## */
    /**
     Called whenever the user taps on the slider.
     
     - parameter inTapGestureRecognizer: The gesture recognizer that executed the tap.
     */
    @objc func sliderTapped(_ inTapGestureRecognizer: UIGestureRecognizer) {
        guard let sliderControl = sliderControl else { return }
        
        let pointTapped: CGPoint = inTapGestureRecognizer.location(in: self)

        let sliderOriginX = sliderControl.frame.origin.x
        let sliderWidth = sliderControl.frame.size.width
        let newValue = Float((pointTapped.x - sliderOriginX) * CGFloat(sliderControl.maximumValue) / sliderWidth)

        sliderControl.setValue(newValue, animated: true)
        sliderControl.sendActions(for: .valueChanged)
    }
}

/* ###################################################################################################################################### */
// MARK: - Main View Controller -
/* ###################################################################################################################################### */
/**
 This is the main view controller for the weekday/time selector tab.
 */
class VMF_MainSearchViewController: VMF_TabBaseViewController {
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
    }
    
    /* ################################################################## */
    /**
     This is an alias for the tuple type we use for time-mapped meeting data.
     */
    typealias MappedSet = (time: String, meetings: [MeetingInstance])
    
    /* ################################################################## */
    /**
     How many seconds are in a 24-hour day.
     */
    fileprivate static let _oneDayInSeconds = TimeInterval(86400)
    
    /* ################################################################## */
    /**
     The image to use for our ascending sort.
     */
    private static let _sortButtonASCImage = UIImage(systemName: "arrowtriangle.up.fill")?.applyingSymbolConfiguration(UIImage.SymbolConfiguration(scale: .large))
    
    /* ################################################################## */
    /**
     The image to use for our descending sort.
     */
    private static let _sortButtonDESCImage = UIImage(systemName: "arrowtriangle.down.fill")?.applyingSymbolConfiguration(UIImage.SymbolConfiguration(scale: .large))

    /* ################################################################## */
    /**
     The height of section headers.
     */
    private static let _sectionTitleHeightInDisplayUnits = CGFloat(30)
    
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
     The segue ID, for inspecting individual meetings.
     */
    private static let _inspectMeetingSegueID = "inspect-meeting"

    /* ################################################################## */
    /**
     This is our query instance.
     */
    private static var _queryInstance = SwiftBMLSDK_Query(serverBaseURI: URL(string: "https://littlegreenviper.com/LGV_MeetingServer/Tests/entrypoint.php"))
    
    /* ################################################################## */
    /**
     This handles the meeting collection for this.
     */
    private var _meetings: [MeetingInstance] = []

    /* ################################################################## */
    /**
     This handles the server data.
     */
    private var _virtualService: SwiftBMLSDK_MeetingLocalTimezoneCollection? {
        didSet {
            mapData()
            setTimeSlider()
        }
    }

    /* ################################################################## */
    /**
     This is an array of the time-mapped meeting data.
     */
    private var _mappedDataset = [[MappedSet]]()

    /* ################################################################## */
    /**
     This is set to true, if the "now" segment is selected.
     */
    private var _wasNow = false
    
    /* ################################################################## */
    /**
     This is set to true, if the sort direction is ascending.
     */
    private var _isSortAsc = true { didSet { setSortButton() }}
    
    /* ################################################################## */
    /**
     This is set to true, if we are in name search mode.
     */
    private var _isNameSearchMode: Bool = false {
        didSet {
            searchTextField?.isHidden = !_isNameSearchMode
            weekdaySegmentedSwitch?.isHidden = _isNameSearchMode
            timeSlider?.isHidden = _isNameSearchMode && (7 != weekdaySegmentedSwitch?.selectedSegmentIndex)
            valueTable?.reloadData()
        }
    }
    
    /* ################################################################## */
    /**
     Used for the "Pull to Refresh"
     */
    private weak var _refreshControl: UIRefreshControl?

    /* ################################################################## */
    /**
     This is set to true, if the "throbber" is shown (hiding everything else).
     */
    var isThrobbing: Bool = false {
        didSet {
            _refreshControl?.endRefreshing()
            if isThrobbing {
                tabBarController?.tabBar.isHidden = true
                valueTable?.isHidden = true
                mainContainerView?.isHidden = true
                throbber?.isHidden = false
            } else {
                throbber?.isHidden = true
                mainContainerView?.isHidden = false
                valueTable?.isHidden = false
                tabBarController?.tabBar.isHidden = false
            }
        }
    }
    
    /* ################################################################## */
    /**
     This contains all the visible items.
     */
    @IBOutlet weak var mainContainerView: UIView?

    /* ################################################################## */
    /**
     The weekday switch.
     */
    @IBOutlet weak var weekdaySegmentedSwitch: UISegmentedControl?

    /* ################################################################## */
    /**
     The slider control for the time of day.
     */
    @IBOutlet weak var timeSlider: VMF_TimeSlider?
    
    /* ################################################################## */
    /**
     The text field for name search mode.
     */
    @IBOutlet weak var searchTextField: UITextField?
    
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
    
    @IBOutlet weak var sortLabel: UILabel?
    
    /* ################################################################## */
    /**
     The ascending/descending sort button.
     */
    @IBOutlet weak var sortButton: UIButton?
    
    /* ################################################################## */
    /**
     The "Throbber" view
     */
    @IBOutlet weak var throbber: UIView?
}

/* ###################################################################################################################################### */
// MARK: Computed Properties
/* ###################################################################################################################################### */
extension VMF_MainSearchViewController {
    /* ################################################################## */
    /**
     Returns meetings with names that begin with the text entered.
     */
    var searchedMeetings: [MeetingInstance] {
        let testString = searchTextField?.text?.lowercased() ?? ""
        
        return (_virtualService?.meetings.filter { mtg in mtg.meeting.name.lowercased().beginsWith(testString) }.map { $0.meeting } ?? [])
    }
    
    /* ################################################################## */
    /**
     The data for display in the table.
     
     It is arranged in sections, with the "meetings" member, containing the row data.
     */
    var tableFood: [(sectionTitle: String, meetings: [MeetingInstance])] {
        let meetings = (_isNameSearchMode ? searchedMeetings : _meetings).sorted { a, b in
            var ret = false
            
            let tzA = Self.getMeetingTimeZone(a)
            let tzB = Self.getMeetingTimeZone(b)

            if 7 == weekdaySegmentedSwitch?.selectedSegmentIndex {
                let currentIntegerTime = Calendar.current.component(.hour, from: .now) * 100 + Calendar.current.component(.minute, from: .now)
                var aTime = a.adjustedIntegerStartTime
                var bTime = b.adjustedIntegerStartTime

                if aTime > currentIntegerTime {
                    aTime -= 2400
                }

                if bTime > currentIntegerTime {
                    bTime -= 2400
                }
                
                ret = aTime < bTime ? true :
                        tzA != tzB ? false :
                            a.sortableMeetingType < b.sortableMeetingType ? true :
                                a.sortableMeetingType != b.sortableMeetingType ? false :
                                    a.name < b.name
            } else if let sortType = sortSegmentedSwitch?.selectedSegmentIndex,
                      let sortBy = SortType(rawValue: sortType) {
                switch sortBy {
                case .timeZone:
                    ret = tzA < tzB ? true :
                        tzA != tzB ? false :
                            a.sortableMeetingType < b.sortableMeetingType ? true :
                                a.sortableMeetingType != b.sortableMeetingType ? false :
                                    a.name < b.name

                case .type:
                    ret = a.sortableMeetingType < b.sortableMeetingType ? true :
                        a.sortableMeetingType != b.sortableMeetingType ? false :
                            tzA < tzB ? true :
                                tzA != tzB ? false :
                                    a.name < b.name
                    
                case .name:
                    ret = a.name < b.name ? true :
                        a.name != b.name ? false :
                            tzA < tzB ? true :
                                tzA != tzB ? false :
                                    a.sortableMeetingType < b.sortableMeetingType
                }
            }
            
            return self._isSortAsc ? ret : !ret
        }
        
        return [(sectionTitle: "", meetings: meetings)]
    }
}

/* ###################################################################################################################################### */
// MARK: Base Class Overrides
/* ###################################################################################################################################### */
extension VMF_MainSearchViewController {
    /* ################################################################## */
    /**
     Called when the view hierarchy has loaded.
     */
    override func viewDidLoad() {
        super.viewDidLoad()
        let refresh = UIRefreshControl()
        refresh.addTarget(self, action: #selector(findMeetings), for: .valueChanged)
        _refreshControl = refresh
        valueTable?.refreshControl = refresh
        sortLabel?.text = sortLabel?.text?.localizedVariant
        isThrobbing = true
        for index in (0..<(sortSegmentedSwitch?.numberOfSegments ?? 0)) {
            sortSegmentedSwitch?.setTitle(sortSegmentedSwitch?.titleForSegment(at: index)?.localizedVariant, forSegmentAt: index)
        }
        setUpWeekdayControl()
        findMeetings()
    }
    
    /* ################################################################## */
    /**
     Called just before the view is to appear.
     
     - parameter inIsAnimated: True, if the appearance is animated.
     */
    override func viewWillAppear(_ inIsAnimated: Bool) {
        super.viewWillAppear(inIsAnimated)
        _wasNow = false
        _isSortAsc = true
    }
}

/* ###################################################################################################################################### */
// MARK: Static Functions
/* ###################################################################################################################################### */
extension VMF_MainSearchViewController {
    /* ################################################################## */
    /**
     This converts the selected weekday into the 1 == Sun format needed for the meeting data.
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
extension VMF_MainSearchViewController {
    /* ################################################################## */
    /**
     This sets the proper days into the weekday control.
     */
    func setUpWeekdayControl() {
        for index in 0..<7 {
            var currentDay = index + Calendar.current.firstWeekday
            
            if 7 < currentDay {
                currentDay -= 7
            }
            
            let weekdaySymbols = Calendar.current.shortWeekdaySymbols
            let weekdayName = weekdaySymbols[currentDay - 1]

            weekdaySegmentedSwitch?.setTitle(weekdayName, forSegmentAt: index)
        }
        
        weekdaySegmentedSwitch?.setTitle(weekdaySegmentedSwitch?.titleForSegment(at: 7)?.localizedVariant, forSegmentAt: 7)
    }
    
    /* ################################################################## */
    /**
     This applies the selected days meetings to the slider, in a form it understands.
     */
    func setTimeSlider(forceNow inForceNow: Bool = false) {
        guard let weekdaySwitch = self.weekdaySegmentedSwitch else { return }
        
        let selectedWeekdayIndex = Self.unMapWeekday(weekdaySwitch.selectedSegmentIndex + 1) - 1

        guard let timeSlider = timeSlider,
              (0..<_mappedDataset.count).contains(selectedWeekdayIndex)
        else { return }
        
        var oldTimeAsTime = -1
        var oldTimeForcedValue = -1
        
        if !timeSlider.meetings.isEmpty {
            let oldValue = Int(timeSlider.sliderControl?.value ?? 0)
            if oldValue == 0 || oldValue == (timeSlider.meetings.count - 1) {
                oldTimeForcedValue = oldValue
            }
            oldTimeAsTime = timeSlider.meetings[oldValue].meetings.first?.adjustedIntegerStartTime ?? -1
        }
        
        timeSlider.meetings = _mappedDataset[selectedWeekdayIndex]
        
        // All the funkiness below, is trying to keep the slider pointed to the correct time, or, just above it.
        
        guard -1 == oldTimeForcedValue else {
            timeSlider.sliderControl?.value = Float (0 == oldTimeForcedValue ? 0 : timeSlider.sliderControl?.maximumValue ?? Float(timeSlider.meetings.count - 1))
            timeSlider.sliderControl?.sendActions(for: .valueChanged)
            return
        }
        
        let hour = Calendar.current.component(.hour, from: .now)
        let minute = Calendar.current.component(.minute, from: .now)

        guard 0 <= oldTimeAsTime else { return }
        
        if inForceNow {
            oldTimeAsTime = hour * 100 + minute
        }
        
        var newValue = 0
        var index = 0
        var newTime = -1
        
        timeSlider.meetings.forEach {
            if $0.meetings.first?.adjustedIntegerStartTime == oldTimeAsTime {
                newTime = $0.meetings.first?.adjustedIntegerStartTime ?? -1
                newValue = index
            }
            
            index += 1
        }
        
        if newTime != oldTimeAsTime,
           0 < oldTimeAsTime {
            index = 0
            newValue = 0
            timeSlider.meetings.forEach {
                if 0 == newValue,
                   ($0.meetings.first?.adjustedIntegerStartTime ?? -1) >= oldTimeAsTime {
                    newValue = index
                }
                index += 1
            }
        }
        
        timeSlider.sliderControl?.value = Float (newValue)
        timeSlider.sliderControl?.sendActions(for: .valueChanged)
    }
    
    /* ################################################################## */
    /**
     This maps the times for the selected day.
     */
    func mapData() {
        _mappedDataset = []
        
        guard let virtualService = _virtualService else { return }

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
            
            _mappedDataset.append(daySet)
        }
    }
    
    /* ################################################################## */
    /**
     Sets the day and time to our current day/time.
     */
    func setToNow() {
        let day = Calendar.current.component(.weekday, from: .now)
        let hour = Calendar.current.component(.hour, from: .now)
        let minute = Calendar.current.component(.minute, from: .now)
        let firstWeekday = Calendar.current.firstWeekday
        var currentDay =  (day - firstWeekday)
        
        if 0 > currentDay {
            currentDay += 7
        }
        
        guard (0..<7).contains(currentDay) else { return }
        
        weekdaySegmentedSwitch?.selectedSegmentIndex = currentDay
        weekdaySegmentedSwitch?.sendActions(for: .valueChanged)
        
        guard !_mappedDataset.isEmpty,
              let timeSlider = timeSlider,
              (1..._mappedDataset.count).contains(day)
        else { return }

        timeSlider.meetings = _mappedDataset[day - 1]
        
        var index = -1
        var counter = 0
        let compTime = (hour * 100) + minute
        
        timeSlider.meetings.forEach {
            if let time = $0.meetings.first?.adjustedIntegerStartTime,
               -1 == index,
               time >= compTime {
                index = counter
            }
            
            counter += 1
        }
        
        timeSlider.sliderControl?.setValue(Float(index), animated: true)
        timeSlider.sliderControl?.sendActions(for: .valueChanged)
    }
    
    /* ################################################################## */
    /**
     Called to set up the sort button.
     */
    func setSortButton() {
        let image = _isSortAsc ? Self._sortButtonASCImage : Self._sortButtonDESCImage
        
        sortButton?.setImage(image, for: .normal)
    }
}

/* ###################################################################################################################################### */
// MARK: Callbacks
/* ###################################################################################################################################### */
extension VMF_MainSearchViewController {
    /* ################################################################## */
    /**
     Called when the user selects a time slot for the meetings.
     
     - parameter inSelectedIndex: The time control slider value, as an index.
     */
    func timeSliderChanged(_ inSelectedIndex: Int, slider inSlider: VMF_TimeSlider) {
        _meetings = inSlider.selectedMeetings
        valueTable?.reloadData()
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
     Fetches all of the virtual meetings (hybrid and pure virtual).
     
     Marked ObjC, with an ignored parameter, so it can be called from pull to refresh.
     
     - parameter: ignored
     */
    @objc func findMeetings(_: Any! = nil) {
        isThrobbing = true
        _virtualService = nil
        _ = SwiftBMLSDK_MeetingLocalTimezoneCollection(query: Self._queryInstance) { inCollection in
            DispatchQueue.main.async {
                self._virtualService = inCollection
                self.isThrobbing = false
                self.setToNow()
            }
        }
    }
    
    /* ################################################################## */
    /**
     Called when the user taps on the search button.
     
     - parameter: ignored
     */
    @IBAction func searchButtonHit(_: Any) {
        _isNameSearchMode = !_isNameSearchMode
    }
    
    /* ################################################################## */
    /**
     Called when the user taps on the control.
     
     - parameter inTapGestureRecognizer: The tap gesture
     */
    @IBAction func weekdayTapped(_ inTapGestureRecognizer: UITapGestureRecognizer) {
        guard let weekdaySwitch = weekdaySegmentedSwitch else { return }
        let pointTapped: CGPoint = inTapGestureRecognizer.location(in: weekdaySwitch)
        let lastx = weekdaySwitch.bounds.width - (weekdaySwitch.bounds.width / CGFloat(weekdaySwitch.numberOfSegments))
        
        if (weekdaySwitch.numberOfSegments - 1) == weekdaySwitch.selectedSegmentIndex,
           pointTapped.x >= lastx {
            inTapGestureRecognizer.cancelsTouchesInView = true
            setToNow()
        } else {
            inTapGestureRecognizer.cancelsTouchesInView = false
        }
    }

    /* ################################################################## */
    /**
     Called when the user selects a particular weekday.
     
     - parameter inWeekdaySegmentedControl: The segmented control that was changed.
     */
    @IBAction func weekdaySelected(_ inWeekdaySegmentedControl: UISegmentedControl) {
        if 7 == inWeekdaySegmentedControl.selectedSegmentIndex {
            timeSlider?.isHidden = true
            _wasNow = true
            guard let virtualService = _virtualService else { return }

            _meetings = virtualService.meetings.filter { $0.isInProgress }.map { $0.meeting }
            
            sortSegmentedSwitch?.isEnabled = false

            valueTable?.reloadData()
        } else {
            sortSegmentedSwitch?.isEnabled = true
            timeSlider?.isHidden = false
            setTimeSlider(forceNow: _wasNow)
            _wasNow = false
        }
    }
    
    /* ################################################################## */
    /**
     The segmented switch that sets the sort was changed
     
     - parameter inSwitch: The switch that changed.
     */
    @IBAction func sortChanged(_ inSwitch: UISegmentedControl) {
        valueTable?.reloadData()
    }
    
    /* ################################################################## */
    /**
     The sort button was hit
     
     - parameter: Ignored
     */
    @IBAction func sortButtonHit(_: Any) {
        _isSortAsc = !_isSortAsc
        valueTable?.reloadData()
    }
    
    /* ################################################################## */
    /**
     The search text was changed.
     
     - parameter inTextField: The search text field (ignored)
     */
    @IBAction func searchTextChanged(_: UITextField) {
        guard _isNameSearchMode else { return }
        
        valueTable?.reloadData()
    }
}

/* ###################################################################################################################################### */
// MARK: UITableViewDataSource Conformance
/* ###################################################################################################################################### */
extension VMF_MainSearchViewController: UITableViewDataSource {
    /* ################################################################## */
    /**
     Returns the number of sections to display.
     
     - parameter in: The table view (ignored)
     - returns: The number of sections to display.
     */
    func numberOfSections(in: UITableView) -> Int { tableFood.count }
    
    /* ################################################################## */
    /**
     - parameter: The table view (ignored)
     - parameter numberOfRowsInSection: The 0-based section index.
     - returns: The number of meetings to display.
     */
    func tableView(_: UITableView, numberOfRowsInSection inSectionIndex: Int) -> Int { tableFood[inSectionIndex].meetings.count }
    
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
extension VMF_MainSearchViewController: UITableViewDelegate {
    /* ################################################################## */
    /**
     Called when a cell is selected. We will use this to open the user viewer.
     
     - parameter: The table view (ignored)
     - parameter willSelectRowAt: The index path of the cell we are selecting.
     - returns: nil (all the time).
     */
    func tableView(_: UITableView, willSelectRowAt inIndexPath: IndexPath) -> IndexPath? {
        let meeting = _meetings[inIndexPath.row]
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
