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
class VMF_DayTimeSearchViewController: VMF_TabBaseViewController, VMF_MasterTableControllerProtocol {
    var myController: (any VMF_MasterTableControllerProtocol)?
    
    /* ################################################################## */
    /**
     This handles the server data.
     */
    weak var virtualService: SwiftBMLSDK_MeetingLocalTimezoneCollection?
    
    /* ################################################################## */
    /**
     This tracks the current embedded table controller.
     */
    var tableDisplayController: VMF_EmbeddedTableControllerProtocol?
    
    /* ################################################################## */
    /**
     This is our page view controller.
     */
    weak var pageViewController: VMF_DayTimeSearchPageViewController?
    
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
     This has the "mostly organized" meeting data.
     
     The meetings are organized in ascending local time, arranged by weekday, with [0] being Sunday.
     */
    var organizedMeetings: [[MeetingInstance]] = []

    /* ################################################################## */
    /**
     This is set to true, if the "throbber" is shown (hiding everything else).
     */
    var isThrobbing: Bool = false {
        didSet {
            if isThrobbing {
                tableContainerView?.isHidden = true
                throbber?.isHidden = false
            } else {
                throbber?.isHidden = true
                tableContainerView?.isHidden = false
            }
        }
    }

    /* ################################################################## */
    /**
     The embedded table controller container view.
     */
    @IBOutlet weak var tableContainerView: UIView!
    
    /* ################################################################## */
    /**
     The "Throbber" view
     */
    @IBOutlet weak var throbber: UIView?
}

/* ###################################################################################################################################### */
// MARK: Computed Properties
/* ###################################################################################################################################### */
extension VMF_DayTimeSearchViewController {
    /* ################################################################## */
    /**
     These are the meetings that are currently in progress. They are sorted in ascending local start time.
     */
    var inProgressMeetings: [MeetingInstance] {
        self.virtualService?.meetings.compactMap { $0.isInProgress ? $0.meeting : nil }.sorted { a, b in
            if a.adjustedIntegerStartTime < b.adjustedIntegerStartTime {
                return true
            } else if a.adjustedIntegerStartTime < b.adjustedIntegerStartTime {
                return false
            } else if a.timeZone.identifier < b.timeZone.identifier {
                return true
            } else if a.timeZone.identifier > b.timeZone.identifier {
                return false
            } else {
                return a.name.lowercased() < b.name.lowercased()
            }
        } ?? []
    }

    /* ################################################################## */
    /**
     Returns now, in terms understood by the meeting search.
     
     weekday is the current weekday, transformed to the meeting data (1 is Sunday)
     currentIntegerTime is the current time, as an integer (hours * 100 + minute).
     */
    var nowIs: (weekday: Int, currentIntegerTime: Int) {
        let day = Calendar.current.component(.weekday, from: .now)
        let hour = Calendar.current.component(.hour, from: .now)
        let minute = Calendar.current.component(.minute, from: .now)
        let firstWeekday = Calendar.current.firstWeekday
        var currentDay =  (day - firstWeekday)
        
        if 0 > currentDay {
            currentDay += 7
        }
        
        guard (0..<7).contains(currentDay) else { return (weekday: 0, currentIntegerTime: 0) }
        
        return (weekday: currentDay + 1, currentIntegerTime: hour * 100 + minute)
    }
}

/* ###################################################################################################################################### */
// MARK: Instance Methods
/* ###################################################################################################################################### */
extension VMF_DayTimeSearchViewController {
    /* ################################################################## */
    /**
     Called to load the meetings from the server.
     
     - parameter completion: A simple, no-parameter completion. It is always called in the main thread.
     */
    func loadMeetings(completion inCompletion: @escaping () -> Void) {
        isThrobbing = true
        virtualService = nil
        searchMeetings = []
        organizedMeetings = []
        VMF_AppDelegate.findMeetings { [weak self] inVirtualService in
            self?.virtualService = inVirtualService
            
            self?.searchMeetings = inVirtualService?.meetings.map { $0.meeting }.sorted { a, b in
                let aLower = a.name.lowercased()
                let bLower = b.name.lowercased()
                
                if aLower < bLower {
                    return true
                } else if aLower > bLower {
                    return false
                } else if a.timeZone.identifier < b.timeZone.identifier {
                    return true
                } else if a.timeZone.identifier > b.timeZone.identifier {
                    return false
                } else {
                    return a.adjustedIntegerStartTime < b.adjustedIntegerStartTime
                }
            } ?? []
            
            for index in 1..<8 {
                self?.organizedMeetings.append(self?.searchMeetings.compactMap { index == $0.adjustedWeekday ? $0 : nil }.sorted { a, b in
                    if a.adjustedIntegerStartTime < b.adjustedIntegerStartTime {
                        return true
                    } else if a.adjustedIntegerStartTime < b.adjustedIntegerStartTime {
                        return false
                    } else if a.timeZone.identifier < b.timeZone.identifier {
                        return true
                    } else if a.timeZone.identifier > b.timeZone.identifier {
                        return false
                    } else {
                        return a.name.lowercased() < b.name.lowercased()
                    }
                } ?? [])
            }
            
            DispatchQueue.main.async {
                self?.isThrobbing = false
                inCompletion()
            }
        }
    }

    /* ################################################################## */
    /**
     Get the meetings for a particular weekday.
     
     - parameter for: The 1-based (1 is Sunday) weekday index
     - returns: a Dictionary, with the weekday's meetings, organized by localized start time (the key)
     */
    func getDailyMeetings(for inWeekdayIndex: Int) -> [Int: [MeetingInstance]] {
        guard (1..<(organizedMeetings.count + 1)).contains(inWeekdayIndex) else { return [:] }
        
        var ret = [Int: [MeetingInstance]]()
        
        organizedMeetings[inWeekdayIndex - 1].forEach {
            let key = $0.adjustedIntegerStartTime
            if nil == ret[key] {
                ret[key] = [$0]
            } else {
                ret[key]?.append($0)
            }
        }
        
        return ret
    }
}

/* ###################################################################################################################################### */
// MARK: Base Class Overrides
/* ###################################################################################################################################### */
extension VMF_DayTimeSearchViewController {
    /* ################################################################## */
    /**
     */
    override func viewDidLoad() {
        super.viewDidLoad()
    
        loadMeetings {
            guard let newViewController = self.getTableDisplay(for: 0, time: 0) else { return }
            self.pageViewController?.setViewControllers([newViewController], direction: .forward, animated: false)
        }
    }
    
    /* ################################################################## */
    /**
     */
    override func prepare(for inSegue: UIStoryboardSegue, sender: Any?) {
        if let destination = inSegue.destination as? VMF_DayTimeSearchPageViewController {
            destination.delegate = self
            destination.dataSource = self
            pageViewController = destination
        }
    }
    
    /* ################################################################## */
    /**
     */
    func getTableDisplay(for inDayIndex: Int, time inTimeIndex: Int) -> VMF_EmbeddedTableController? {
        guard (-1...organizedMeetings.count).contains(inDayIndex),
              let newViewController = storyboard?.instantiateViewController(withIdentifier: VMF_EmbeddedTableController.storyboardID) as? VMF_EmbeddedTableController else { return nil }
        newViewController.myController = self
        newViewController.timeIndex = inTimeIndex
        newViewController.dayIndex = inDayIndex
        var meetings = [MeetingInstance]()
        
        if -1 == inDayIndex {
            meetings = searchMeetings
        } else if 0 == inDayIndex {
            meetings = inProgressMeetings
        } else {
            meetings = getDailyMeetings(for: inDayIndex)[inTimeIndex] ?? []
        }
        
        newViewController.meetings = meetings
        return newViewController
    }
}

/* ###################################################################################################################################### */
// MARK: UIPageViewControllerDataSource Conformance
/* ###################################################################################################################################### */
extension VMF_DayTimeSearchViewController: UIPageViewControllerDataSource {
    /* ################################################################## */
    /**
     */
    func pageViewController(_ inPageViewController: UIPageViewController, viewControllerBefore inBeforeViewController: UIViewController) -> UIViewController? {
        guard let oldViewController = inBeforeViewController as? VMF_EmbeddedTableController else { return nil }
        
        var timeIndex = oldViewController.timeIndex + 1
        var dayIndex = oldViewController.dayIndex

        var meetings = [MeetingInstance]()
        if -1 == dayIndex {
            meetings = searchMeetings
        } else if 0 == dayIndex {
            meetings = inProgressMeetings
        } else {
            meetings = getDailyMeetings(for: dayIndex)[timeIndex] ?? []
        }

        if timeIndex > meetings.count {
            timeIndex = 0
            dayIndex += 1
            
            if 7 < dayIndex {
                dayIndex = 1
            }
        }
        
        guard let newViewController = getTableDisplay(for: dayIndex, time: timeIndex) else { return nil }
        return newViewController
    }
    
    /* ################################################################## */
    /**
     */
    func pageViewController(_ inPageViewController: UIPageViewController, viewControllerAfter inAfterViewController: UIViewController) -> UIViewController? {
        guard let oldViewController = inAfterViewController as? VMF_EmbeddedTableController else { return nil }
        var timeIndex = oldViewController.timeIndex - 1
        var dayIndex = oldViewController.dayIndex

        if timeIndex < 0 {
            timeIndex = organizedMeetings.count
            dayIndex -= 1
            
            if 1 > dayIndex {
                dayIndex = 7
            }
            
            timeIndex = organizedMeetings[dayIndex - 1].count - 1
        }
        
        guard let newViewController = getTableDisplay(for: dayIndex, time: timeIndex) else { return nil }
        return newViewController
    }
}

/* ###################################################################################################################################### */
// MARK: UIPageViewControllerDelegate Conformance
/* ###################################################################################################################################### */
extension VMF_DayTimeSearchViewController: UIPageViewControllerDelegate {
}

/* ###################################################################################################################################### */
// MARK: - Page View Controller -
/* ###################################################################################################################################### */
/**
 This is the page controller that embeds our tables.
 */
class VMF_DayTimeSearchPageViewController: UIPageViewController {
}
