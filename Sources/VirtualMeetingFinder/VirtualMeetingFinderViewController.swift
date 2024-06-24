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
// MARK: - Array Extension for Meetings -
/* ###################################################################################################################################### */
extension Array where Element == SwiftBMLSDK_MeetingLocalTimezoneCollection.CachedMeeting {
    func meetingsOnWeekday(weekdayIndex inWeekdayIndex: Int) -> [SwiftBMLSDK_MeetingLocalTimezoneCollection.CachedMeeting] {
        filter { $0.meeting.weekday == inWeekdayIndex }
    }
}

/* ###################################################################################################################################### */
// MARK: - Special Slider Setup for Times -
/* ###################################################################################################################################### */
/**
 */
class VirtualMeetingFinderTimeSlider: UIControl {
    struct Time {
        /* ############################################################## */
        /**
         */
        let hour: Int
        
        /* ############################################################## */
        /**
         */
        let minute: Int
    }
    
    /* ################################################################################################################################## */
    // MARK: Aggregator Class for Each Tick Mark
    /* ################################################################################################################################## */
    /**
     */
    class TickView: UIView {
        /* ############################################################## */
        /**
         */
        private static let _labelTickSeparationInDisplayUnits = CGFloat(4)
        
        /* ############################################################## */
        /**
         */
        private static let _tickWidthInDisplayUnits = CGFloat(4)
        
        /* ############################################################## */
        /**
         */
        private static let _labelFont = UIFont.systemFont(ofSize: 12)
        
        /* ############################################################## */
        /**
         */
        private static let _labelColor = UIColor.gray
        
        /* ############################################################## */
        /**
         */
        private static let _tickColor = UIColor.gray

        /* ############################################################## */
        /**
         */
        var time: Time?
        
        /* ############################################################## */
        /**
         */
        weak var tickMark: UIView?
        
        /* ############################################################## */
        /**
         */
        weak var label: UILabel?
        
        /* ############################################################## */
        /**
         */
        override func layoutSubviews() {
            super.layoutSubviews()
            
            guard let hour = time?.hour,
                  let minute = time?.minute,
                  let date = Calendar.current.date(from: DateComponents(hour: hour, minute: minute))
            else { return }
            
            let dateFormatter = DateFormatter()
            dateFormatter.dateStyle = .none
            dateFormatter.timeStyle = .short
            
            let displayString = dateFormatter.string(from: date)
            
            if nil == label {
                let tempLabel = UILabel()
                addSubview(tempLabel)
                label = tempLabel
                tempLabel.translatesAutoresizingMaskIntoConstraints = false
                tempLabel.bottomAnchor.constraint(equalTo: bottomAnchor).isActive = true
                tempLabel.leftAnchor.constraint(equalTo: leftAnchor).isActive = true
                tempLabel.rightAnchor.constraint(equalTo: rightAnchor).isActive = true
                tempLabel.textColor = Self._labelColor
                tempLabel.font = Self._labelFont
                tempLabel.text = displayString
            }
            
            if nil == tickMark {
                let tempTickMark = UIView()
                addSubview(tempTickMark)
                tickMark = tempTickMark
                tempTickMark.translatesAutoresizingMaskIntoConstraints = false
                tempTickMark.topAnchor.constraint(equalTo: topAnchor).isActive = true
                let bottomHook = label?.topAnchor ?? bottomAnchor
                tempTickMark.bottomAnchor.constraint(equalTo: bottomHook, constant: Self._labelTickSeparationInDisplayUnits).isActive = true
                tempTickMark.widthAnchor.constraint(equalToConstant: Self._tickWidthInDisplayUnits).isActive = true
                tempTickMark.layer.cornerRadius = Self._tickWidthInDisplayUnits / 2
                tempTickMark.centerXAnchor.constraint(equalTo: centerXAnchor).isActive = true
                tempTickMark.backgroundColor = Self._tickColor
            }
        }
    }

    /* ################################################################## */
    /**
     */
    private var _ticks: [TickView] = []

    /* ################################################################## */
    /**
     */
    var meetings = [VirtualMeetingFinderViewController.MappedSet]() { didSet { setNeedsLayout() } }
    
    /* ################################################################## */
    /**
     */
    weak var sliderControl: UISlider?

    /* ################################################################## */
    /**
     */
    @IBOutlet weak var controller: VirtualMeetingFinderViewController?
    
    /* ################################################################## */
    /**
     */
    var selectedMeetings: [MeetingInstance] {
        guard let value = sliderControl?.value else { return [] }
        let intValue = max(0, min((meetings.count - 1), Int(round(value))))
        
        return meetings[intValue].meetings
    }
}

/* ###################################################################################################################################### */
// MARK: Base Class Overrides
/* ###################################################################################################################################### */
extension VirtualMeetingFinderTimeSlider {
    /* ################################################################## */
    /**
     */
    override func layoutSubviews() {
        super.layoutSubviews()
        
        if nil == sliderControl {
            let tempSlider = UISlider()
            
            addSubview(tempSlider)
            sliderControl = tempSlider
            tempSlider.translatesAutoresizingMaskIntoConstraints = false
            tempSlider.topAnchor.constraint(equalTo: topAnchor).isActive = true
            tempSlider.leftAnchor.constraint(equalTo: leftAnchor).isActive = true
            tempSlider.rightAnchor.constraint(equalTo: rightAnchor).isActive = true
            tempSlider.addTarget(self, action: #selector(sliderChanged), for: .valueChanged)
        }
        
        sliderControl?.minimumValue = 0
        sliderControl?.maximumValue = Float(meetings.count)
        sliderControl?.value = 0
        
        addTicks()
    }
}

/* ###################################################################################################################################### */
// MARK: Instance Methods
/* ###################################################################################################################################### */
extension VirtualMeetingFinderTimeSlider {
    /* ################################################################## */
    /**
     */
    func addTicks() {
        _ticks.forEach {
            $0.removeFromSuperview()
        }
        
        _ticks = []
    }
}

/* ###################################################################################################################################### */
// MARK: Callbacks
/* ###################################################################################################################################### */
extension VirtualMeetingFinderTimeSlider {
    /* ################################################################## */
    /**
     */
    @objc func sliderChanged(_ inSlider: UISlider) {
        let value = inSlider.value
        let intValue = max(0, min((meetings.count - 1), Int(round(value))))
        inSlider.value = Float(intValue)
        controller?.timeSliderChanged(intValue, slider: self)
    }
}

/* ###################################################################################################################################### */
// MARK: - Main View Controller -
/* ###################################################################################################################################### */
/**
 */
class VirtualMeetingFinderViewController: UIViewController {
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
     This is our query instance.
     */
    private static var _queryInstance = SwiftBMLSDK_Query(serverBaseURI: URL(string: "https://littlegreenviper.com/LGV_MeetingServer/Tests/entrypoint.php"))

    /* ################################################################## */
    /**
     This handles the server data.
     */
    private var _virtualService: SwiftBMLSDK_MeetingLocalTimezoneCollection?

    /* ################################################################## */
    /**
     This is an array of the time-mapped meeting data.
     */
    private var mappedDataset = [[MappedSet]]()
    
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
    @IBOutlet weak var timeSlider: VirtualMeetingFinderTimeSlider?

    /* ################################################################## */
    /**
     The "Throbber" view
     */
    @IBOutlet weak var throbber: UIView?
    
    /* ################################################################## */
    /**
     This is set to true, if the "throbber" is shown (hiding everything else).
     */
    var isThrobbing: Bool = false {
        didSet {
            if isThrobbing {
                mainContainerView?.isHidden = true
                throbber?.isHidden = false
            } else {
                throbber?.isHidden = true
                mainContainerView?.isHidden = false
            }
        }
    }
    
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
}

/* ###################################################################################################################################### */
// MARK: Base Class Overrides
/* ###################################################################################################################################### */
extension VirtualMeetingFinderViewController {
    /* ################################################################## */
    /**
     Called when the view hierarchy has loaded.
     */
    override func viewDidLoad() {
        super.viewDidLoad()
        isThrobbing = true
        setUpWeekdayControl()
        findMeetings {
            self.setTimeSlider()
            self.isThrobbing = false
        }
    }
}

/* ###################################################################################################################################### */
// MARK: Instance Methods
/* ###################################################################################################################################### */
extension VirtualMeetingFinderViewController {
    /* ################################################################## */
    /**
     Fetches all of the virtual meetings (hybrid and pure virtual).
     
     - parameter completion: A tail completion proc. This is always called in the main thread.
     */
    func findMeetings(completion inCompletion: (() -> Void)?) {
        _ = SwiftBMLSDK_MeetingLocalTimezoneCollection(query: Self._queryInstance) { inCollection in
            DispatchQueue.main.async {
                self._virtualService = inCollection
                self.mapData()
                inCompletion?()
            }
        }
    }
    
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
    }
    
    /* ################################################################## */
    /**
     */
    func setTimeSlider() {
        guard let weekdaySwitch = self.weekdaySegmentedSwitch else { return }
        
        let selectedWeekdayIndex = Self.unMapWeekday(weekdaySwitch.selectedSegmentIndex + 1) - 1
        
        timeSlider?.meetings = mappedDataset[selectedWeekdayIndex]
    }
    
    /* ################################################################## */
    /**
     This maps the times for the selected day.
     */
    func mapData() {
        mappedDataset = []
        
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
                let string = (1200 == timeInst) ? "SLUG-NOON".localizedVariant : (2359 == timeInst) ? "SLUG-MIDNIGHT".localizedVariant : meetings[0].timeString
                daySet.append(MappedSet(time: string, meetings: meetings))
            }
            
            mappedDataset.append(daySet)
        }
    }
}

/* ###################################################################################################################################### */
// MARK: Callbacks
/* ###################################################################################################################################### */
extension VirtualMeetingFinderViewController {
    /* ################################################################## */
    /**
     Called when the user selects a particular weekday.
     
     - parameter inWeekdaySegmentedControl: The segmented control that was changed.
     */
    @IBAction func weekdaySelected(_ inWeekdaySegmentedControl: UISegmentedControl) {
        setTimeSlider()
    }
    
    /* ################################################################## */
    /**
     Called when the user selects a time slot for the meetings.
     
     - parameter inSelectedIndex: The time control slider value, as an index.
     */
    func timeSliderChanged(_ inSelectedIndex: Int, slider inSlider: VirtualMeetingFinderTimeSlider) {
        guard !inSlider.selectedMeetings.isEmpty else { return }
        
        print("\(inSlider.meetings[inSelectedIndex].time), (\(inSlider.meetings[inSelectedIndex].meetings.count))")
    }
}

