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
// MARK: - Main View Controller -
/* ###################################################################################################################################### */
/**
 This is the main view controller for the weekday/time selector tab.
 */
class VMF_DayTimeSearchViewController: VMF_TabBaseViewController {
    /* ################################################################## */
    /**
     This handles the server data.
     */
    weak var virtualService: SwiftBMLSDK_MeetingLocalTimezoneCollection?

    /* ################################################################## */
    /**
     This is an array of the time-mapped meeting data.
     */
    var mappedDataset = [[VMF_EmbeddedTableControllerProtocol.MappedSet]]()

    /* ################################################################## */
    /**
     This tracks the embedded table controller.
     */
    var tableDisplayController: VMF_EmbeddedTableControllerProtocol?

    /* ################################################################## */
    /**
     This is set to true, if we are in name search mode.
     */
    var isNameSearchMode: Bool = false

    /* ################################################################## */
    /**
     Contains the search text filter.
     */
    var searchText: String = "" { didSet { } }

    /* ################################################################## */
    /**
     Storage for our search meeting source
     */
    var searchMeetings: [MeetingInstance] = []

    /* ################################################################## */
    /**
     Called to load the meetings from the server.
     
     - parameter completion: A simple, no-parameter completion. It is always called in the main thread.
     */
    func loadMeetings(completion inCompletion: @escaping () -> Void) {
        /* ############################################################## */
        /**
         Callback for the meting search.
         
         - parameter inVirtualService: A reference to the search results.
         */
        func meetingCallback(_ inVirtualService: SwiftBMLSDK_MeetingLocalTimezoneCollection?) {
            virtualService = inVirtualService
            searchMeetings = inVirtualService?.meetings.map { $0.meeting }.sorted { a, b in a.name.lowercased() < b.name.lowercased() } ?? []
            DispatchQueue.main.async { inCompletion() }
        }
        virtualService = nil
        searchMeetings = []
        VMF_AppDelegate.findMeetings(completion: meetingCallback)
    }
    
    /* ################################################################## */
    /**
     Sets the day and time to our current day/time.
     */
    func setToNow() {
//        let day = Calendar.current.component(.weekday, from: .now)
//        let hour = Calendar.current.component(.hour, from: .now)
//        let minute = Calendar.current.component(.minute, from: .now)
//        let firstWeekday = Calendar.current.firstWeekday
//        var currentDay =  (day - firstWeekday)
//        
//        if 0 > currentDay {
//            currentDay += 7
//        }
//        
//        guard (0..<7).contains(currentDay),
//              (1...mappedDataset.count).contains(day)
//        else { return }
//        
//        let todaysMeetings = mappedDataset[day - 1]
    }
}

/* ###################################################################################################################################### */
// MARK: - Page View Controller -
/* ###################################################################################################################################### */
/**
 This is the page controller that embeds our tables.
 */
class VMF_DayTimeSearchPageViewController: UIPageViewController {
    
}
