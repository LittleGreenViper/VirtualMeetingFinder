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
        
        phoneButton?.isHidden = true
        videoButton?.isHidden = true
        globeButton?.isHidden = true
        phoneInfoTextView?.isHidden = true
        
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
