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
 This displays one meeting.
 */
class VMF_MeetingViewController: VMF_BaseViewController {
    /* ################################################################## */
    /**
     The meeting that this screen is displaying.
     */
    var meeting: MeetingInstance?
    
    /* ################################################################## */
    /**
     The label that displays the meeting start time and weekday.
     */
    @IBOutlet weak var timeAndDayLabel: UILabel?

    /* ################################################################## */
    /**
     This label is displayed if the meeting is in progress.
     */
    @IBOutlet weak var inProgressLabel: UILabel?

    /* ################################################################## */
    /**
     The label that displays the meeting timezone.
     */
    @IBOutlet weak var timeZoneLabel: UILabel?
    
    /* ################################################################## */
    /**
     This contains the tappable links.
     */
    @IBOutlet weak var linkContainer: UIStackView?
    
    /* ################################################################## */
    /**
     This is the phone in button.
     */
    @IBOutlet weak var phoneButton: UIButton?
    
    /* ################################################################## */
    /**
     This is the video link button.
     */
    @IBOutlet weak var videoButton: UIButton?
    
    /* ################################################################## */
    /**
     This is the Web link button.
     */
    @IBOutlet weak var globeButton: UIButton?
    
    /* ################################################################## */
    /**
     Contains any phone info that can't be turned into a URL.
     */
    @IBOutlet weak var phoneInfoTextView: UITextView?
    
    /* ################################################################## */
    /**
     Contains the in-person meeting stuff.
     */
    @IBOutlet weak var inPersonContainer: UIStackView?
    
    /* ################################################################## */
    /**
     The heading for the in-person meeting stuff.
     */
    @IBOutlet weak var inPersonHeader: UILabel?

    /* ################################################################## */
    /**
     The text view that displays an address for in-person meetings.
     */
    @IBOutlet weak var inPersonAddressTextView: UITextView?
}

/* ###################################################################################################################################### */
// MARK: Static Functions
/* ###################################################################################################################################### */
extension VMF_MeetingViewController {
    /* ################################################################## */
    /**
     "Cleans" a URI.
     
     - parameter urlString: The URL, as a String. It can be optional.
     
     - returns: an optional String. This is the given URI, "cleaned up" ("https://" or "tel:" may be prefixed)
     */
    private static func _cleanURI(urlString inURLString: String?) -> String? {
        guard var ret: String = inURLString?.urlEncodedString,
              let regex = try? NSRegularExpression(pattern: "^(http://|https://|tel://|tel:)", options: .caseInsensitive)
        else { return nil }
        
        // We specifically look for tel URIs.
        let wasTel = ret.lowercased().beginsWith("tel:")
        
        // Yeah, this is pathetic, but it's quick, simple, and works a charm.
        ret = regex.stringByReplacingMatches(in: ret, options: [], range: NSRange(location: 0, length: ret.count), withTemplate: "")

        if ret.isEmpty {
            return nil
        }
        
        if wasTel {
            ret = "tel:" + ret
        } else {
            ret = "https://" + ret
        }
        
        return ret
    }
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
        /* ################################################################## */
        /**
         This simply strips out all non-decimal characters in the string, leaving only valid decimal digits.
         */
        func stripPhoneNumber(from inString: String) -> String {
            let allowedChars = CharacterSet(charactersIn: "0123456789 ()-+")
            guard !inString.reduce(false, { current, next in
                // The higher-order function stuff will convert each character into an aggregate integer, which then becomes a Unicode scalar. Very primitive, but shouldn't be a problem for us, as we only need a very limited ASCII set.
                guard !current,
                      let cha = UnicodeScalar(next.unicodeScalars.map { $0.value }.reduce(0, +))
                else { return true }
                return !allowedChars.contains(cha)
            })
            else { return "" }
            
            return inString.decimalOnly
        }
        
        super.viewDidLoad()
        setScreenTitle()
        setTimeZone()
        setTimeAndWeekday()
        inProgressLabel?.text = inProgressLabel?.text?.localizedVariant
        phoneButton?.isHidden = true
        videoButton?.isHidden = true
        globeButton?.isHidden = true
        phoneInfoTextView?.isHidden = true
        inPersonContainer?.isHidden = true
        
        var directPhoneNumberString = meeting?.directPhoneURI?.absoluteString.replacingOccurrences(of: "https://", with: "tel:") ?? ""
        
        if directPhoneNumberString.isEmpty,
           let numbersTemp = meeting?.virtualPhoneNumber {
            let numbers = stripPhoneNumber(from: numbersTemp)
            if !numbers.isEmpty {
                directPhoneNumberString = "tel:\(numbers)"
            }
        }
        
        if !directPhoneNumberString.isEmpty,
           let directURI = URL(string: directPhoneNumberString),
           UIApplication.shared.canOpenURL(directURI) {
            phoneButton?.isHidden = false
        }
        
        if nil != meeting?.directAppURI {
            videoButton?.isHidden = false
        }
        
        if nil == meeting?.directAppURI,
           nil == meeting?.directPhoneURI,
           let webLinkURL = meeting?.virtualURL,
           UIApplication.shared.canOpenURL(webLinkURL) {
            globeButton?.isHidden = false
        } 
        
        if (phoneButton?.isHidden ?? true),
           let vPhone = meeting?.virtualPhoneNumber,
           !vPhone.isEmpty {
            phoneInfoTextView?.isHidden = false
            phoneInfoTextView?.text = String(format: "SLUG-PHONE-NUMBER-FORMAT".localizedVariant, vPhone)
        }
        
        if let basicAddress = meeting?.basicInPersonAddress,
           !basicAddress.isEmpty {
            inPersonContainer?.isHidden = false
            inPersonHeader?.text = inPersonHeader?.text?.localizedVariant
            inPersonAddressTextView?.text = basicAddress
        }
    }
    
    /* ################################################################## */
    /**
     Called before the screen appears.
     
     Let the app know that we're here.
     
     - parameter inIsAnimated: True, if the appearance is animated.
     */
    override func viewWillAppear(_ inIsAnimated: Bool) {
        super.viewWillAppear(inIsAnimated)
        VMF_AppDelegate.openMeeting = self
    }
    
    /* ################################################################## */
    /**
     Called before the screen disappears.
     
     Let the app know that we're done.
     
     - parameter inIsAnimated: True, if the disappearance is animated.
     */
    override func viewWillDisappear(_ inIsAnimated: Bool) {
        super.viewWillDisappear(inIsAnimated)
        VMF_AppDelegate.openMeeting = nil
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
        guard var meeting = meeting,
              (1..<8).contains(meeting.weekday)
        else { return }
        
        let weekday = Calendar.current.weekdaySymbols[meeting.adjustedWeekday - 1]
        let prevTime = meeting.getPreviousStartDate(isAdjusted: true)
        let startTime = meeting.getNextStartDate(isAdjusted: true)

        if 0 < meeting.duration {
            timeAndDayLabel?.text = String(format: "SLUG-WEEKDAY-TIME-DURATION-FORMAT".localizedVariant, weekday, startTime.localizedTime, startTime.addingTimeInterval(meeting.duration).localizedTime)
            inProgressLabel?.isHidden = !(prevTime...prevTime.addingTimeInterval(meeting.duration)).contains(.now)
        } else {
            timeAndDayLabel?.text = String(format: "SLUG-WEEKDAY-TIME-FORMAT".localizedVariant, weekday, startTime.localizedTime)
            inProgressLabel?.isHidden = true
        }
    }
    
    /* ################################################################## */
    /**
     Sets the time zone string (or hides it).
     */
    func setTimeZone() {
        guard let meeting = meeting else { return }
        
        let timeZoneString = getMeetingTimeZone(meeting)
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

/* ###################################################################################################################################### */
// MARK: Callbacks
/* ###################################################################################################################################### */
extension VMF_MeetingViewController {
    /* ################################################################## */
    /**
     The phone in button was hit.
     
     - parameter: ignored
     */
    @IBAction func phoneButtonHit(_: Any) {
        var directPhoneNumberString = meeting?.directPhoneURI?.absoluteString.replacingOccurrences(of: "https://", with: "tel:") ?? ""
        
        if directPhoneNumberString.isEmpty,
           let numbers = meeting?.virtualPhoneNumber?.decimalOnly,
           !numbers.isEmpty {
            directPhoneNumberString = "tel:\(numbers)"
        }
        
        if !directPhoneNumberString.isEmpty,
           let directURI = URL(string: directPhoneNumberString),
           UIApplication.shared.canOpenURL(directURI) {
            VMF_AppDelegate.open(url: directURI)
        }
    }
    
    /* ################################################################## */
    /**
     The globe button was hit.
     
     - parameter: ignored
     */
    @IBAction func globeButtonHit(_: Any) {
        if let webLinkURL = meeting?.virtualURL,
           UIApplication.shared.canOpenURL(webLinkURL) {
            VMF_AppDelegate.open(url: webLinkURL)
        }
    }
    
    /* ################################################################## */
    /**
     The video button was hit.
     
     - parameter: ignored
     */
    @IBAction func videoButtonHit(_: Any) {
        if let videoLinkURL = meeting?.directAppURI {
            VMF_AppDelegate.open(url: videoLinkURL)
        }
    }
}
