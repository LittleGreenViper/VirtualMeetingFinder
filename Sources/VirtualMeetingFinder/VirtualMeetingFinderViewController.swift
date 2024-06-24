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
    @IBOutlet weak var controller: VirtualMeetingFinderViewController?
    
    /* ################################################################## */
    /**
     */
    weak var sliderControl: UISlider?
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
        controller?.timeSliderChanged(inSlider)
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
     */
    @IBOutlet weak var weekdaySegmentedSwitch: UISegmentedControl?

    /* ################################################################## */
    /**
     */
    @IBOutlet weak var timeSlider: VirtualMeetingFinderTimeSlider?

    /* ################################################################## */
    /**
     */
    @IBOutlet weak var typeSegmentedSwitch: UISegmentedControl?

    /* ################################################################## */
    /**
     */
    @IBOutlet weak var throbber: UIView?
}

/* ###################################################################################################################################### */
// MARK: Base Class Overrides
/* ###################################################################################################################################### */
extension VirtualMeetingFinderViewController {
    /* ################################################################## */
    /**
     */
    override func viewDidLoad() {
        super.viewDidLoad()
        throbber?.isHidden = false
        findMeetings {
            self.throbber?.isHidden = true
            print("DUN")
        }
    }
}

/* ###################################################################################################################################### */
// MARK: Instance Methods
/* ###################################################################################################################################### */
extension VirtualMeetingFinderViewController {
    /* ################################################################## */
    /**
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
     Fetches all of the virtual meetings (hybrid and pure virtual).
     
     - parameter completion: A tail completion proc. This is always called in the main thread.
     */
    func findMeetings(completion inCompletion: (() -> Void)?) {
        _virtualService = SwiftBMLSDK_MeetingLocalTimezoneCollection(query: Self._queryInstance) { inCollection in
            DispatchQueue.main.async {
                guard let switchMan = self.typeSegmentedSwitch else { return }
                
                for index in 0..<switchMan.numberOfSegments {
                    var count = 0
                    
                    switch index {
                    case 0:
                        count = inCollection.meetings.count
                    case 1:
                        count = inCollection.hybridMeetings.count
                    case 2:
                        count = inCollection.virtualMeetings.count
                    default:
                        break
                    }
                    let countSuffix = 0 < count ? " (\(count))" : ""
                    let title = "SLUG-VIRTUAL-SWITCH-\(index)".localizedVariant + countSuffix
                    switchMan.setTitle(title, forSegmentAt: index)
                }
            }
            
            inCompletion?()
        }
    }
}

/* ###################################################################################################################################### */
// MARK: Callbacks
/* ###################################################################################################################################### */
extension VirtualMeetingFinderViewController {
    /* ################################################################## */
    /**
     */
    @IBAction func typeSelected(_ inTypeSegmentedControl: UISegmentedControl) {
        
    }
    
    /* ################################################################## */
    /**
     */
    @IBAction func weekdaySelected(_ inWeekdaySegmentedControl: UISegmentedControl) {
        
    }
    
    /* ################################################################## */
    /**
     */
    func timeSliderChanged(_ inSlider: UISlider) {
        print("HAI")
    }
}

