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
            minimumValue = 0
            maximumValue = Float(meetings.count - 1)
            setNeedsLayout()
        }
    }
    
    /* ################################################################## */
    /**
     This is the container for the entire control
     */
    weak var mainContainer: UIStackView?
    
    /* ################################################################## */
    /**
     This is the container for the lower part of the slider aggregate.
     */
    weak var container: UIView?

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
     The minimum value of the control.
     */
    @IBInspectable var minimumValue: Float = 0 { didSet { valueStepper?.minimumValue = Double(minimumValue) } }

    /* ################################################################## */
    /**
     The maximum value of the control.
     */
    @IBInspectable var maximumValue: Float = 0 { didSet { valueStepper?.maximumValue = Double(maximumValue) } }
    
    /* ################################################################## */
    /**
     The value of the control.
     */
    @IBInspectable var value: Float = 0 {
        didSet {
            valueStepper?.value = Double(value)
            let intValue = Int(max(minimumValue, min(maximumValue, value)))
            
            valueLabel?.text = !meetings.isEmpty ? meetings[intValue].time : ""
            
            sendActions(for: .valueChanged)
        }
    }

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
        guard let value = valueStepper?.value,
              !meetings.isEmpty
        else { return [] }
        
        let intValue = max(0, min((meetings.count - 1), Int(round(value))))
        
        return meetings[intValue].meetings
    }
    
    /* ################################################################## */
    /**
     The value of the control.
     */
    func setValue(_ inValue: Float, animated inAnimated: Bool) {
        valueStepper?.value = Double(inValue)
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
        
        minimumValue = 0
        maximumValue = max(0, Float(meetings.count - 1))
        value = Float(max(0, min((meetings.count - 1), Int(round(valueStepper?.value ?? 0)))))

        setUpControl()
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
    func setUpControl() {
        if nil == mainContainer {
            let stackView = UIStackView()
            addSubview(stackView)
            mainContainer = stackView
            stackView.translatesAutoresizingMaskIntoConstraints = false
            stackView.topAnchor.constraint(equalTo: topAnchor).isActive = true
            stackView.leftAnchor.constraint(equalTo: leftAnchor).isActive = true
            stackView.rightAnchor.constraint(equalTo: rightAnchor).isActive = true
            stackView.bottomAnchor.constraint(equalTo: bottomAnchor).isActive = true
        }
        
        if let mainContainer = mainContainer,
           nil == container {
            let containerView = UIView()
            mainContainer.addArrangedSubview(containerView)
            container = containerView
            containerView.translatesAutoresizingMaskIntoConstraints = false
            containerView.leftAnchor.constraint(equalTo: mainContainer.leftAnchor).isActive = true
            containerView.rightAnchor.constraint(equalTo: mainContainer.rightAnchor).isActive = true
        }
        
        if nil == valueLabel,
           let containerView = container {
            let label = UILabel()
            label.textAlignment = .center
            label.font = .systemFont(ofSize: 15)
            containerView.addSubview(label)
            valueLabel = label
            label.translatesAutoresizingMaskIntoConstraints = false
            label.centerXAnchor.constraint(equalTo: containerView.centerXAnchor).isActive = true
            label.setContentHuggingPriority(.required, for: .horizontal)
        }
        
        if nil == valueStepper,
           let containerView = container,
           let label = valueLabel {
            let stepper = UIStepper()
            stepper.autorepeat = true
            stepper.minimumValue = Double(minimumValue)
            stepper.maximumValue = Double(maximumValue)
            stepper.stepValue = 1
            containerView.addSubview(stepper)
            valueStepper = stepper
            stepper.translatesAutoresizingMaskIntoConstraints = false
            stepper.addTarget(self, action: #selector(stepperChanged), for: .valueChanged)
            stepper.leftAnchor.constraint(greaterThanOrEqualTo: label.rightAnchor, constant: 4).isActive = true
            stepper.rightAnchor.constraint(equalTo: containerView.rightAnchor).isActive = true
            stepper.centerYAnchor.constraint(equalTo: label.centerYAnchor).isActive = true
            stepper.bottomAnchor.constraint(equalTo: containerView.bottomAnchor).isActive = true
        }
        
        if let containerView = container,
           nil == resetButton,
           let label = valueLabel {
            let reset = UIButton(type: .roundedRect)
            reset.addTarget(self, action: #selector(resetButtonHit), for: .touchUpInside)
            reset.setTitle("SLUG-RESET".localizedVariant, for: .normal)
            containerView.addSubview(reset)
            resetButton = reset
            reset.translatesAutoresizingMaskIntoConstraints = false
            reset.leftAnchor.constraint(equalTo: containerView.leftAnchor, constant: 8).isActive = true
            reset.rightAnchor.constraint(lessThanOrEqualTo: label.leftAnchor).isActive = true
            reset.centerYAnchor.constraint(equalTo: label.centerYAnchor).isActive = true
        }
        
        if !meetings.isEmpty {
            let intValue = Int(max(minimumValue, min(maximumValue, value)))
            valueLabel?.text = meetings[intValue].time
            valueStepper?.isEnabled = true
        } else {
            valueLabel?.text = ""
            valueStepper?.isEnabled = false
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
        value = inSlider.value
    }
    
    /* ################################################################## */
    /**
     Called whenever the stepper control changes.
     
     - parameter inSlider: The slider control that changed.
     */
    @objc func stepperChanged(_ inStepper: UIStepper) {
        value = Float(inStepper.value)
    }
    
    /* ################################################################## */
    /**
     Called whenever the reset button is hit
     
     - parameter: ignored
     */
    @objc func resetButtonHit(_: Any) {
        controller?.setToNow()
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
        
        /* ############################################################## */
        /**
         The sort is via the meeting start time.
         */
        case time = 3
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
     This is used to restore the bottom of the stack view, when the keyboard is hidden.
     */
    private var _atRestConstant: CGFloat = 0

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
     This is set to true, if we are in name search mode.
     */
    var isNameSearchMode: Bool = false {
        didSet {
            searchTextContainer?.isHidden = !isNameSearchMode
            weekdayContainer?.isHidden = isNameSearchMode
            sortContainer?.isHidden = isNameSearchMode || tableFood.isEmpty || (1 >= tableFood[0].meetings.count)
            
            if isNameSearchMode {
                _refreshControl?.isEnabled = false
                searchTextField?.becomeFirstResponder()
            } else {
                _refreshControl?.isEnabled = true
                searchTextField?.resignFirstResponder()
            }
            
            timeSlider?.isHidden = isNameSearchMode || (7 == weekdaySegmentedSwitch?.selectedSegmentIndex)
            _cachedTableFood = []
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
    
    /* ################################################################## */
    /**
     The container for the weekday switch.
     */
    @IBOutlet weak var weekdayContainer: UIStackView?
    
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
    
    /* ################################################################## */
    /**
     The container for the search text field.
     */
    @IBOutlet weak var searchTextContainer: UIStackView?

    /* ################################################################## */
    /**
     The bottom constraint of the text area. We use this to shrink the text area, when the keyboard is shown.
     */
    @IBOutlet weak var bottomConstraint: NSLayoutConstraint?

    /* ################################################################## */
    /**
     The "Throbber" view
     */
    @IBOutlet weak var throbber: UIView?
    
    /* ################################################################## */
    /**
     The swipe rcognizer for increasing time.
     */
    @IBOutlet weak var leftSwipeRecognizer: UISwipeGestureRecognizer?

    /* ################################################################## */
    /**
     The swipe rcognizer for decreasing time.
     */
    @IBOutlet weak var rightSwipeRecognizer: UISwipeGestureRecognizer?
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
        
        guard !testString.isEmpty else { return _cachedSearchMeetings }
        
        return (_cachedSearchMeetings.filter { $0.name.lowercased().beginsWith(testString) })
    }
    
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
        valueTable?.sectionHeaderTopPadding = CGFloat(0)
        sortLabel?.text = sortLabel?.text?.localizedVariant
        searchTextField?.placeholder = searchTextField?.placeholder?.localizedVariant
        isThrobbing = true
        _atRestConstant = bottomConstraint?.constant ?? 0
        for index in (0..<(sortSegmentedSwitch?.numberOfSegments ?? 0)) {
            sortSegmentedSwitch?.setTitle(sortSegmentedSwitch?.titleForSegment(at: index)?.localizedVariant, forSegmentAt: index)
        }
        
        let leftSwipe = UISwipeGestureRecognizer(target: self, action: #selector(leftSwipeRecognizerHit))
        leftSwipe.direction = .left
        valueTable?.addGestureRecognizer(leftSwipe)
        let rightSwipe = UISwipeGestureRecognizer(target: self, action: #selector(rightSwipeRecognizerHit))
        rightSwipe.direction = .right
        valueTable?.addGestureRecognizer(rightSwipe)
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

        setSortButton()
        
        if isNameSearchMode {
            _refreshControl?.isEnabled = false
            searchTextContainer?.isHidden = false
            weekdayContainer?.isHidden = true
            sortContainer?.isHidden = true
            timeSlider?.isHidden = true
            searchTextField?.becomeFirstResponder()
        } else {
            _refreshControl?.isEnabled = true
            searchTextContainer?.isHidden = true
            weekdayContainer?.isHidden = false
            sortContainer?.isHidden = false
            timeSlider?.isHidden = 7 == weekdaySegmentedSwitch?.selectedSegmentIndex
            _cachedTableFood = []
        }
        
        VMF_AppDelegate.searchController = self
        
        valueTable?.reloadData()
    }
    
    /* ################################################################## */
    /**
     Called just before the view disappears.
     
     - parameter inIsAnimated: True, if the disappearance is animated.
     */
    override func viewWillDisappear(_ inIsAnimated: Bool) {
        VMF_AppDelegate.searchController = nil
        
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
            
            let weekdaySymbols = Calendar.current.veryShortStandaloneWeekdaySymbols
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
            let oldValue = Int(timeSlider.value)
            if oldValue == 0 || oldValue == (timeSlider.meetings.count - 1) {
                oldTimeForcedValue = oldValue
            }
            oldTimeAsTime = timeSlider.meetings[oldValue].meetings.first?.adjustedIntegerStartTime ?? -1
        }
        
        timeSlider.meetings = _mappedDataset[selectedWeekdayIndex]
        
        // All the funkiness below, is trying to keep the slider pointed to the correct time, or, just above it.
        
        guard -1 == oldTimeForcedValue else {
            timeSlider.value = Float(0 == oldTimeForcedValue ? 0 : timeSlider.maximumValue)
            timeSlider.sendActions(for: .valueChanged)
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
        
        timeSlider.value = Float (newValue)
        timeSlider.sendActions(for: .valueChanged)
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
        _firstTime = false
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

        let todaysMeetings = _mappedDataset[day - 1]
        
        timeSlider.setNeedsLayout()
        timeSlider.meetings = todaysMeetings
        
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
        
        timeSlider.setValue(Float(index), animated: true)
        timeSlider.sendActions(for: .valueChanged)
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
extension VMF_MainSearchViewController {
    /* ################################################################## */
    /**
     Called when the user selects a time slot for the meetings.
     
     - parameter inTimeSlider: The time control slider.
     */
    @IBAction func sliderChanged(_ inTimeSlider: VMF_TimeSlider) {
        _meetings = inTimeSlider.selectedMeetings
        _cachedTableFood = []
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
        guard !isNameSearchMode else {
            _refreshControl?.endRefreshing()
            return
        }
        isThrobbing = true
        _virtualService = nil
        _ = SwiftBMLSDK_MeetingLocalTimezoneCollection(query: Self._queryInstance) { inCollection in
            DispatchQueue.main.async {
                self._virtualService = inCollection
                self._cachedSearchMeetings = inCollection.meetings.map{ $0.meeting }.sorted { a, b in a.name.lowercased() < b.name.lowercased() }
                self.isThrobbing = false
                if self._firstTime {
                    self.setToNow()
                }
            }
        }
    }
    
    /* ################################################################## */
    /**
     This is called just before the keyboard shows. We use this to "nudge" the display items up.
     
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
     This is called just before the keyboard shows. We use this to return the login items to their original position.
     
     - parameter notification: The notification being passed in.
     */
    @objc func keyboardWillHide(notification: NSNotification) {
        DispatchQueue.main.async { [weak self] in
            self?.bottomConstraint?.constant = self?._atRestConstant ?? 0
        }
    }

    /* ################################################################## */
    /**
     Called when the user taps on the search button.
     
     - parameter: ignored
     */
    @IBAction func searchButtonHit(_: Any) {
        isNameSearchMode = !isNameSearchMode
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
            sortSegmentedSwitch?.setEnabled(true, forSegmentAt: SortType.time.rawValue)
            sortSegmentedSwitch?.selectedSegmentIndex = SortType.time.rawValue
            sortSegmentedSwitch?.sendActions(for: .valueChanged)
            _cachedTableFood = []
            valueTable?.reloadData()
        } else {
            timeSlider?.isHidden = false
            setTimeSlider(forceNow: _wasNow)
            _wasNow = false
            if 3 == sortSegmentedSwitch?.selectedSegmentIndex {
                sortSegmentedSwitch?.selectedSegmentIndex = SortType.timeZone.rawValue
            }
            sortSegmentedSwitch?.setEnabled(false, forSegmentAt: SortType.time.rawValue)
        }
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
    
    /* ################################################################## */
    /**
     The swipe rcognizer for increasing time was executed.
     
     - parameter: Ignored
     */
    @IBAction func leftSwipeRecognizerHit(_: UISwipeGestureRecognizer) {
        guard !(timeSlider?.isHidden ?? true) else { return }
        
        timeSlider?.value += 1
    }

    /* ################################################################## */
    /**
     The swipe rcognizer for decreasing time was executed.
     
     - parameter: Ignored
     */
    @IBAction func rightSwipeRecognizerHit(_: UISwipeGestureRecognizer) {
        guard !(timeSlider?.isHidden ?? true) else { return }
        
        timeSlider?.value -= 1
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
extension VMF_MainSearchViewController: UITableViewDelegate {
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
