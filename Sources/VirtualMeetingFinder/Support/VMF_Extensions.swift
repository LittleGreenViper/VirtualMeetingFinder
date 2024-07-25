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
import RVS_BasicGCDTimer

/* ###################################################################################################################################### */
// MARK: - Abstraction for the Meeting Type -
/* ###################################################################################################################################### */
/* ###################################################################### */
/**
 This allows us to play around with the SDK.
 */
public typealias MeetingInstance = SwiftBMLSDK_Parser.Meeting

/* ###################################################################################################################################### */
// MARK: - Special Button for "Tap and Hold" -
/* ###################################################################################################################################### */
/**
 This allows single taps, or hold to repeat (like steppers).
 */
class VMF_TapHoldButton: UIControl {
    /* ################################################################## */
    /**
     The gesture recognizer for single taps.
     */
    private weak var _tapGestureRecognizer: UITapGestureRecognizer?
    
    /* ################################################################## */
    /**
     The gesture recognizer for long-press repeat.
     */
    private weak var _longHoldGestureRecognizer: UILongPressGestureRecognizer?
    
    /* ################################################################## */
    /**
     This manages the repeated calls.
     */
    private var _repeater: RVS_BasicGCDTimer?
    
    /* ################################################################## */
    /**
     The view that contains the button image.
     */
    private weak var _displayImageView: UIImageView?

    /* ################################################################## */
    /**
     This is how often we repeat, when long-pressing.
     */
    @IBInspectable var repeatFrequencyInSeconds = TimeInterval(0.15)
    
    /* ################################################################## */
    /**
     This is the image that is displayed in the button.
     */
    @IBInspectable var displayImage: UIImage? { didSet { setNeedsLayout() } }
}

/* ###################################################################################################################################### */
// MARK: Callbacks
/* ###################################################################################################################################### */
extension VMF_TapHoldButton {
    /* ################################################################## */
    /**
     Called for a single tap
     
     - parameter: The recognizer (ignored).
     */
    @objc func tapGesture(_: UITapGestureRecognizer) {
        sendActions(for: .primaryActionTriggered)
    }
    
    /* ################################################################## */
    /**
     Called for a long-press. The action will be repeated at a regular interval.
     
     - parameter inGesture: The gesture recognizer instance.
     */
    @objc func longPressGesture(_ inGesture: UILongPressGestureRecognizer) {
        switch inGesture.state {
        case .began:
            _repeater = RVS_BasicGCDTimer(timeIntervalInSeconds: repeatFrequencyInSeconds, onlyFireOnce: false, queue: .main) { _, _ in self.sendActions(for: .primaryActionTriggered) }
            _repeater?.resume()
            
        case .ended, .cancelled:
            _repeater?.invalidate()
            _repeater = nil
            
        default:
            break
        }
    }
}

/* ###################################################################################################################################### */
// MARK: Base Class Overrides
/* ###################################################################################################################################### */
extension VMF_TapHoldButton {
    /* ################################################################## */
    /**
     Called when the views are laid out.
     
     We use this to initialize the object.
     */
    override func layoutSubviews() {
        super.layoutSubviews()
        
        _displayImageView?.removeFromSuperview()
        
        if let displayImage = displayImage {
            let tempView = UIImageView(image: displayImage)
            tempView.contentMode = .scaleAspectFit
            addSubview(tempView)
            _displayImageView = tempView
            tempView.translatesAutoresizingMaskIntoConstraints = false
            tempView.topAnchor.constraint(equalTo: topAnchor, constant: 4).isActive = true
            tempView.leftAnchor.constraint(equalTo: leftAnchor, constant: 4).isActive = true
            tempView.bottomAnchor.constraint(equalTo: bottomAnchor, constant: 4).isActive = true
            tempView.rightAnchor.constraint(equalTo: rightAnchor, constant: 4).isActive = true
        }
        
        if nil == _longHoldGestureRecognizer {
            let tempGesture = UILongPressGestureRecognizer(target: self, action: #selector(longPressGesture))
            addGestureRecognizer(tempGesture)
            _longHoldGestureRecognizer = tempGesture
        }

        if nil == _tapGestureRecognizer,
           let lp = _longHoldGestureRecognizer {
            let tempGesture = UITapGestureRecognizer(target: self, action: #selector(tapGesture))
            tempGesture.require(toFail: lp)
            addGestureRecognizer(tempGesture)
            _tapGestureRecognizer = tempGesture
        }
    }
}

/* ###################################################################################################################################### */
// MARK: - Date Extension for Localized Strings -
/* ###################################################################################################################################### */
/**
 Adds a special method for localizing our time.
 */
extension Date {
    /* ################################################################## */
    /**
     Localizes the time (not the date).
     */
    var localizedTime: String {
        var ret = ""
        
        let hour = Calendar.current.component(.hour, from: self)
        let minute = Calendar.current.component(.minute, from: self)
        let integerTime = hour * 100 + minute
        
        if 2359 == integerTime {
            ret = "SLUG-MIDNIGHT-TIME".localizedVariant
        } else if 1200 == integerTime {
            ret = "SLUG-NOON-TIME".localizedVariant
        }
        
        if ret.isEmpty {
            let formatter = DateFormatter()
            formatter.dateFormat = .none
            formatter.timeStyle = .short
            ret = formatter.string(from: self)
        }
        
        return ret
    }
}

/* ###################################################################################################################################### */
// MARK: - String Extension -
/* ###################################################################################################################################### */
/**
 This adds various functionality to Strings
 */
extension StringProtocol {
    /* ################################################################## */
    /**
     This tests a string to see if a given substring is present at the start.
     
     - parameter inSubstring: The substring to test.
     
     - returns: true, if the string begins with the given substring.
     */
    func beginsWith(_ inSubstring: String) -> Bool {
        guard let range = range(of: inSubstring),
              range.lowerBound == startIndex
        else { return false }
        return true
    }
    
    /* ################################################################## */
    /**
     This tests a string to see if a given substring is present at the end.
     
     - parameter inSubstring: The substring to test.
     
     - returns: true, if the string ends with the given substring.
     */
    func endsWith(_ inSubstring: String) -> Bool {
        guard let range = range(of: inSubstring),
              range.upperBound == endIndex
        else { return false }
        return true
    }
    
    /* ################################################################## */
    /**
     This tests a string to see if a given substring is present anywhere
     
     - parameter inSubstring: The substring to test.
     
     - returns: true, if the string contains the given substring.
     */
    func contains(_ inSubstring: String) -> Bool {
        guard let range = range(of: inSubstring),
              !range.isEmpty
        else { return false }
        return true
    }
}

/* ###################################################################################################################################### */
// MARK: - Additional Function for Meetings -
/* ###################################################################################################################################### */
/**
 This extension adds some methods to the individual meeting class.
 */
extension MeetingInstance {
    /* ################################################################## */
    /**
     This returns the start weekday. It is adjusted, so may sometimes be different from the one specified by the meeting. It is always in 1 = Sunday space.
     */
    var adjustedWeekday: Int {
        var mutableSelf = self
        
        let startDate = mutableSelf.getNextStartDate(isAdjusted: true)
        
        return Calendar.current.component(.weekday, from: startDate)
    }
    
    /* ################################################################## */
    /**
     This marks our attendance in the app local preferences.
     */
    var iAttend: Bool {
        get { VMF_AppDelegate.prefs.attendance.contains(Int(id)) }
        set {
            let id = Int(id)
            if VMF_AppDelegate.prefs.attendance.contains(id),
               !newValue {
                VMF_AppDelegate.prefs.attendance.removeAll { $0 == id }
            } else if newValue,
                      !VMF_AppDelegate.prefs.attendance.contains(id) {
                VMF_AppDelegate.prefs.attendance.append(id)
            }
        }
    }
    
    /* ################################################################## */
    /**
     If this meeting has a format code for a Service meeting, this returns true.
     */
    var isServiceMeeting: Bool {
        // I know, I know, I should use reduce(), or some other higher-order methodology, but the classic for loop is a lot faster.
        for index in 0..<formats.count {
            switch formats[index].key.lowercased() {
            case "asm", "sub-rp":
                return true
                
            default:
                continue
            }
        }
        
        return false
    }
    
    /* ################################################################## */
    /**
     This is a universal link for this meeting, in this app.
     */
    var linkURL: URL? { URL(string: String(format: "SLUG-UNIVERSAL-LINK-FORMAT".localizedVariant, id)) }
}

/* ###################################################################################################################################### */
// MARK: - Bundle Extension -
/* ###################################################################################################################################### */
/**
 This extension adds a simple accessor to fetch the URL, and an accessor to get the large app icon.
 */
public extension Bundle {
    /* ################################################################## */
    /**
     The root server URI as a string.
     */
    var rootServerURI: String? { object(forInfoDictionaryKey: "VMF_BaseServerURI") as? String }
    
    /* ################################################################## */
    /**
     This returns the largest app icon from the bundle.
     */
    var largeAppIcon: UIImage? {
        // Get the biggest image from our app bundle.
        guard let appIconDictionary = (Bundle.main.infoDictionary?["CFBundleIcons"] as? NSDictionary)?["CFBundlePrimaryIcon"] as? NSDictionary,
              let lastIconName = (appIconDictionary["CFBundleIconFiles"] as? Array<String>)?.last
        else { return nil }
        
        return UIImage(named: lastIconName)
    }
}

/* ###################################################################################################################################### */
// MARK: - SwiftBMLSDK_MeetingLocalTimezoneCollection Extension -
/* ###################################################################################################################################### */
/**
 This extension adds a simple accessor to fetch the meetings that we have marked as ones that we attend.
 */
extension SwiftBMLSDK_MeetingLocalTimezoneCollection {
    /* ################################################################## */
    /**
     These are the meetings that the user has marked as ones that they attend.
     */
    var meetingsThatIAttend: [CachedMeeting] { meetings.filter { $0.meeting.iAttend } }
}
