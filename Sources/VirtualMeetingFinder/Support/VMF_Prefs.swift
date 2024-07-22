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

import Foundation
import RVS_Persistent_Prefs

/* ###################################################################################################################################### */
// MARK: - Persistent Test Harness Settings -
/* ###################################################################################################################################### */
/**
 This stores our various parameters, and also acts as a namespace, for our "global" types.
 */
class VMF_Prefs: RVS_PersistentPrefs {
    /* ################################################################################################################################## */
    // MARK: RVS_PersistentPrefs Conformance
    /* ################################################################################################################################## */
    /**
     This is an enumeration that will list the prefs keys for us.
     */
    enum Keys: String {
        /* ############################################################## */
        /**
         We save a list of the IDs of meetings we attend, here.
         */
        case attendance
        
        /* ############################################################## */
        /**
         If we want to exclude Service meetings from the displayed results, this Boolean is true.
         */
        case excludeServiceMeetings

        /* ############################################################## */
        /**
         These are all the keys, in an Array of String.
         */
        static var allKeys: [String] {
            [
                attendance.rawValue,
                excludeServiceMeetings.rawValue
            ]
        }
    }
    
    /* ################################################################## */
    /**
     This is a list of the keys for our prefs.
     We should use the enum for the keys (rawValue).
     */
    override var keys: [String] { Keys.allKeys }
    
    /* ################################################################## */
    /**
     We cache, to avoid the overhead of constantly reloading the prefs.
     */
    private var _cachedAttendance: [Int]?
    
    /* ################################################################## */
    /**
     We cache, to avoid the overhead of constantly reloading the prefs.
     */
    private var _cachedExcludeServiceMeetings: Bool?
}

/* ###################################################################################################################################### */
// MARK: Public Computed Properties
/* ###################################################################################################################################### */
extension VMF_Prefs {
    /* ################################################################## */
    /**
     This saves our meeting attendance, as a list of meeting IDs.
     */
    var attendance: [Int] {
        get {
            guard nil == _cachedAttendance else { return _cachedAttendance! }
            let ret = values[Keys.attendance.rawValue] as? [Int] ?? []
            _cachedAttendance = ret
            return ret
        }
        set {
            _cachedAttendance = newValue
            values[Keys.attendance.rawValue] = newValue
        }
    }
    
    /* ################################################################## */
    /**
     If we want to exclude Service meetings from the displayed results, this Boolean is true.
     */
    var excludeServiceMeetings: Bool {
        get {
            guard nil == _cachedExcludeServiceMeetings else { return _cachedExcludeServiceMeetings! }
            let ret = values[Keys.excludeServiceMeetings.rawValue] as? Bool ?? true
            _cachedExcludeServiceMeetings = ret
            return ret
        }
        set {
            _cachedExcludeServiceMeetings = newValue
            values[Keys.excludeServiceMeetings.rawValue] = newValue
        }
    }
}
