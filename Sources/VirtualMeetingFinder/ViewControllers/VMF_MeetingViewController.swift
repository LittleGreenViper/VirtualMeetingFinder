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
// MARK: - Meeting Inspector View Controller -
/* ###################################################################################################################################### */
/**
 */
class VMF_MeetingViewController: VMF_BaseViewController {
    /* ################################################################## */
    /**
     The meeting that this screen is displaying.
     */
    var meeting: MeetingInstance?
    
    /* ################################################################## */
    /**
     The label that displays the meeting timezone.
     */
    @IBOutlet weak var timeZoneLabel: UILabel?
    
    /* ################################################################## */
    /**
     The label that displays the meeting start time and weekday.
     */
    @IBOutlet weak var timeAndDayLabel: UILabel?
}

/* ###################################################################################################################################### */
// MARK: Base Class Overrides
/* ###################################################################################################################################### */
extension VMF_MeetingViewController {
    /* ################################################################## */
    /**
     Called when the view hierarchy has loaded.
     */
    override func viewDidLoad() {
        super.viewDidLoad()
        setScreenTitle()
        setTimeZone()
        setTimeAndWeekday()
    }
}

/* ###################################################################################################################################### */
// MARK: Instance Methods
/* ###################################################################################################################################### */
extension VMF_MeetingViewController {
    /* ################################################################## */
    /**
     Sets the time and weekday (local) for the meeting.
     */
    func setTimeAndWeekday() {
        guard let meeting = meeting,
              (1..<8).contains(meeting.weekday)
        else { return }
        
        let weekday = Calendar.current.weekdaySymbols[meeting.weekday - 1]
        let timeInst = meeting.adjustedIntegerStartTime
        let time = (1200 == timeInst) ? "SLUG-NOON-TIME".localizedVariant : (2359 == timeInst) ? "SLUG-MIDNIGHT-TIME".localizedVariant : meeting.timeString

        timeAndDayLabel?.text = String(format: "SLUG-WEEKDAY-TIME-FORMAT".localizedVariant, weekday, time)
    }
    
    /* ################################################################## */
    /**
     Sets the time zone string (or hides it).
     */
    func setTimeZone() {
        guard let meeting = meeting else { return }
        
        let timeZoneString = VMF_MainSearchViewController.getMeetingTimeZone(meeting)
        if !timeZoneString.isEmpty {
            timeZoneLabel?.text = timeZoneString
        } else {
            timeZoneLabel?.isHidden = true
        }
    }
    
    /* ################################################################## */
    /**
     Sets the title of the screen -the meeting name.
     */
    func setScreenTitle() {
        let topLabel = UILabel()
        topLabel.text = meeting?.name
        topLabel.numberOfLines = 0
        topLabel.lineBreakMode = .byWordWrapping
        navigationItem.titleView = topLabel
    }
}
