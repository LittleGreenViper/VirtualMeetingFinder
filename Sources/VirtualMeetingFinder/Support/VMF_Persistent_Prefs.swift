/*
 © Copyright 2024-2026, Little Green Viper Software Development LLC
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
import RVS_PersistentPrefs

/* ###################################################################################################################################### */
// MARK: - Persistent App Preferences -
/* ###################################################################################################################################### */
/**
 Stores attendance selections and the service-meeting filter in local user defaults.
 Attendance is a list of meeting IDs; service meetings are hidden by default.
 */
class VMF_Persistent_Prefs: RVS_PersistentPrefs {
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
}

/* ###################################################################################################################################### */
// MARK: Public Computed Properties
/* ###################################################################################################################################### */
extension VMF_Persistent_Prefs {
     /* ################################################################## */
     /**
      This saves our meeting attendance, as a list of meeting IDs.
      */
     var attendance: [Int] {
          get { values[Keys.attendance.rawValue] as? [Int] ?? [] }
          set {
               values[Keys.attendance.rawValue] = newValue
               VMF_WidgetBridge.preferencesChanged(self)
          }
     }
     
     /* ################################################################## */
     /**
      If we want to exclude Service meetings from the displayed results, this Boolean is true.
      */
     var excludeServiceMeetings: Bool {
          get { values[Keys.excludeServiceMeetings.rawValue] as? Bool ?? true }
          set {
               values[Keys.excludeServiceMeetings.rawValue] = newValue
               VMF_WidgetBridge.preferencesChanged(self)
          }
     }
     
}
