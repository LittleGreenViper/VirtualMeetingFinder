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

/* ###################################################################################################################################### */
// MARK: - Abstraction for the Meeting Type -
/* ###################################################################################################################################### */
/* ###################################################################### */
/**
 This allows us to play around with the SDK.
 */
public typealias MeetingInstance = SwiftBMLSDK_Parser.Meeting

/* ###################################################################################################################################### */
// MARK: - Image Assignment Enum, for Meeting Access Types -
/* ###################################################################################################################################### */
extension SwiftBMLSDK_Parser.Meeting.SortableMeetingType {
    /* ################################################################## */
    /**
     Returns the correct image to use, for the type. Returns nil, if no image available.
     */
    var image: UIImage? {
        var imageName = "G" // Generic Web
        
        switch self {
        case .inPerson: // We don't do in-person, alone
            break
        case .virtual:  // Virtual, and has both video and phone
            imageName = "V-P"
        case .virtual_phone:    // Virtual, phone-only
            imageName = "P"
        case .virtual_video:    // Virtual, video-only
            imageName = "V"
        case .hybrid:           // Hybrid, with both video and phone virtual options
            imageName = "V-P-M"
        case .hybrid_phone:     // Hybrid, with only a phone dial-in option
            imageName = "P-M"
        case .hybrid_video:     // Hybrid, with only a video option
            imageName = "V-M"
        }
        
        return UIImage(named: imageName)
    }
}

/* ###################################################################################################################################### */
// MARK: - Date Extension for Localized Strings -
/* ###################################################################################################################################### */
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
/* ###################################################################### */
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
extension MeetingInstance {
    /* ################################################################## */
    /**
     This allows us to return a string for the meeting time. The return is adjusted and localized, with our strings for noon and midnight.
     */
    var timeString: String {
        var mutableSelf = self
        
        return mutableSelf.getNextStartDate(isAdjusted: true).localizedTime
    }
    
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
        get { VMF_Prefs().attendance.contains(Int(id)) }
        set {
            let id = Int(id)
            if VMF_Prefs().attendance.contains(id),
               !newValue {
                VMF_Prefs().attendance.removeAll { $0 == id }
            } else if newValue,
                      !VMF_Prefs().attendance.contains(id) {
                VMF_Prefs().attendance.append(id)
            }
        }
    }
}

/* ###################################################################################################################################### */
// MARK: - Special Dictionary Extension to Extract Meeting Sets -
/* ###################################################################################################################################### */
/**
 This is applied to the dictionary we use to organize meetings.
 */
extension Dictionary where Key == Int, Value == [MeetingInstance] {
    /* ################################################################## */
    /**
     This returns the key for a time equal to, or immediately after, the given time.
     
     - parameter onOrAfter: The start time, as a military-style integer (HHMM).
     - returns: The key, as a military-style integer. -1, if invalid.
     */
    func getKey(onOrAfter inTimeAsInteger: Int) -> Int {
        keys.sorted().first(where: { $0 >= inTimeAsInteger }) ?? -1
    }
    
    /* ################################################################## */
    /**
     This returns the meetings for a time equal to the given time.
     
     - parameter on: The start time, as a military-style integer (HHMM).
     - returns: An array of meetings that correspond to the time.
     */
    func getMeetings(on inTimeAsInteger: Int) -> [MeetingInstance] { self[inTimeAsInteger] ?? [] }
}

/* ###################################################################################################################################### */
// MARK: - Bundle Extension -
/* ###################################################################################################################################### */
/**
 This extension adds a simple accessor to access the URL.
 */
public extension Bundle {
    /* ################################################################## */
    /**
     The root server URI as a string.
     */
    var rootServerURI: String? { object(forInfoDictionaryKey: "VMF_BaseServerURI") as? String }
}
