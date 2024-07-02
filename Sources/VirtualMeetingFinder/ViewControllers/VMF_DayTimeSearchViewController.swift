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
    /* ################################################################## */
    /**
     The main controller (ignored -just here for the protocol).
     */
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
                weekdayModeSelectorSegmentedSwitch?.isHidden = true
                throbber?.isHidden = false
            } else {
                throbber?.isHidden = true
                weekdayModeSelectorSegmentedSwitch?.isHidden = false
                tableContainerView?.isHidden = false
            }
        }
    }

    /* ################################################################## */
    /**
     The segmented switch that controls the mode.
     */
    @IBOutlet weak var weekdayModeSelectorSegmentedSwitch: UISegmentedControl?
    
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
    
    /* ################################################################## */
    /**
     This returns a new destination controller to use for transitions.
     
     NOTE: If the controller is in text search mode, then the name search controller is returned. If the destination has already been created, it is returned.
     
     - parameter for: The 0-based "day index." If it is 0, though, it is the "in-progress" display.
     - parameter time: The 0-based time index. This is the index of the currently selected time slot.
     - returns: A new (or reused) view controller, for the destination of the transition.
     */
    func getTableDisplay(for inDayIndex: Int, time inTimeIndex: Int) -> UIViewController? {
        let dayIndex = max(0, min(organizedMeetings.count, inDayIndex))
        var timeIndex = max(0, min(inTimeIndex, Int.max - 1))
        var meetings = [MeetingInstance]()

        if isNameSearchMode {
            meetings = searchMeetings
        } else if 0 == dayIndex {
            meetings = inProgressMeetings
        } else {
            let tempMeetings = getDailyMeetings(for: mapWeekday(dayIndex))
            let keys = tempMeetings.keys.sorted()
            timeIndex = max(0, min(timeIndex, keys.count - 1))
            let key = keys[timeIndex]
            meetings = tempMeetings[key] ?? []
        }

        guard let newViewController = storyboard?.instantiateViewController(withIdentifier: VMF_EmbeddedTableController.storyboardID) as? VMF_EmbeddedTableController else { return nil }
        
        newViewController.myController = self
        newViewController.timeIndex = timeIndex
        newViewController.dayIndex = dayIndex
        newViewController.meetings = meetings
        
        if !isNameSearchMode,
           0 < dayIndex {
            guard (0..<7).contains(mapWeekday(dayIndex) - 1) else { return nil }
            let weekdayString = Calendar.current.weekdaySymbols[mapWeekday(dayIndex) - 1]
            let timeString = meetings.first?.timeString ?? "ERROR"
            newViewController.title = String(format: "SLUG-WEEKDAY-TIME-FORMAT".localizedVariant, weekdayString, timeString)
        } else if isNameSearchMode {
            newViewController.title = "SLUG-WEEKDAY-SEARCH".localizedVariant
        } else if 0 == dayIndex {
            newViewController.title = "SLUG-IN-PROGRESS".localizedVariant
        }
        
        return newViewController
    }
}

/* ###################################################################################################################################### */
// MARK: Callbacks
/* ###################################################################################################################################### */
extension VMF_DayTimeSearchViewController {
    /* ################################################################## */
    /**
     The segmented switch that controls the mode was hit.
     
     - parameter inSwitch: The segmented switch.
     */
    @IBAction func weekdayModeSelectorSegmentedSwitchHit(_ inSwitch: UISegmentedControl) {
        let selectedIndex = inSwitch.selectedSegmentIndex
        let timeIndex = tableDisplayController?.timeIndex ?? 0
        if selectedIndex == (inSwitch.numberOfSegments - 1) {
            isNameSearchMode = true
            let dayIndex = tableDisplayController?.dayIndex ?? 0
            guard let newViewController = self.getTableDisplay(for: dayIndex, time: timeIndex)
            else { return }
            self.pageViewController?.setViewControllers([newViewController], direction: .forward, animated: false)
        } else {
            isNameSearchMode = false
            var dayIndex = selectedIndex
            if 0 < selectedIndex {
                dayIndex = unMapWeekday(selectedIndex)
            }
            guard let newViewController = self.getTableDisplay(for: dayIndex, time: timeIndex) else { return }
            self.pageViewController?.setViewControllers([newViewController], direction: .forward, animated: false)
        }
    }
}

/* ###################################################################################################################################### */
// MARK: Base Class Overrides
/* ###################################################################################################################################### */
extension VMF_DayTimeSearchViewController {
    /* ################################################################## */
    /**
     Called when the view hierarchy loads.
     */
    override func viewDidLoad() {
        super.viewDidLoad()
    
        guard let maxIndex = weekdayModeSelectorSegmentedSwitch?.numberOfSegments else { return }
        
        for index in (0..<maxIndex) {
            if 0 == index {
                weekdayModeSelectorSegmentedSwitch?.setTitle("SLUG-NOW".localizedVariant, forSegmentAt: index)
            } else if index == (maxIndex - 1) {
                weekdayModeSelectorSegmentedSwitch?.setImage(UIImage(systemName: "magnifyingglass"), forSegmentAt: index)
            } else {
                weekdayModeSelectorSegmentedSwitch?.setTitle(Calendar.current.veryShortStandaloneWeekdaySymbols[index - 1], forSegmentAt: index)
            }
        }
        
        loadMeetings {
            guard let newViewController = self.getTableDisplay(for: 0, time: 0) else { return }
            self.pageViewController?.setViewControllers([newViewController], direction: .forward, animated: false)
        }
    }
    
    /* ################################################################## */
    /**
     Called before transitioning to another view controller.
     
     - parameter for: The segue instance.
     - parameter sender: ignored.
     */
    override func prepare(for inSegue: UIStoryboardSegue, sender: Any?) {
        if let destination = inSegue.destination as? VMF_DayTimeSearchPageViewController {
            destination.delegate = self
            destination.dataSource = self
            pageViewController = destination
        }
    }
}

/* ###################################################################################################################################### */
// MARK: UIPageViewControllerDataSource Conformance
/* ###################################################################################################################################### */
extension VMF_DayTimeSearchViewController: UIPageViewControllerDataSource {
    /* ################################################################## */
    /**
     Called to fetch the view controller before the current one.
     
     - parameter: The page view controller (ignored).
     - parameter viewControllerBefore: The view controller after (to the right of) the one we want.
     - returns: A new (or reused) view controller to appear before (to the left of) the "before" controller.
     */
    func pageViewController(_: UIPageViewController, viewControllerBefore inBeforeViewController: UIViewController) -> UIViewController? {
        guard !isNameSearchMode,
              let oldViewController = inBeforeViewController as? VMF_EmbeddedTableController
        else { return nil }
        
        var timeIndex = oldViewController.timeIndex
        var dayIndex = max(0, min(organizedMeetings.count, oldViewController.dayIndex))
        
        if 0 == dayIndex {
            timeIndex = Int.max - 1
            dayIndex = organizedMeetings.count
        } else {
            timeIndex -= 1
            
            if 0 > timeIndex {
                dayIndex -= 1
                timeIndex = Int.max - 1
            }
        }
        
        return getTableDisplay(for: dayIndex, time: timeIndex)
    }
    
    /* ################################################################## */
    /**
     Called to fetch the view controller after the current one.
     
     - parameter: The page view controller (ignored).
     - parameter viewControllerBefore: The view controller before (to the left of) the one we want.
     - returns: A new (or reused) view controller to appear after (to the right of) the "before" controller.
     */
    func pageViewController(_: UIPageViewController, viewControllerAfter inAfterViewController: UIViewController) -> UIViewController? {
        guard !isNameSearchMode,
              let oldViewController = inAfterViewController as? VMF_EmbeddedTableController
        else { return nil }
        
        var timeIndex = oldViewController.timeIndex + 1
        var dayIndex = oldViewController.dayIndex
        
        if 0 == dayIndex {
            timeIndex = 0
            dayIndex = 1
        } else if timeIndex >= getDailyMeetings(for: mapWeekday(dayIndex)).count {
            dayIndex += 1
            timeIndex = 0

            if 7 < dayIndex {
                dayIndex = 0
            }
        }
        
        return getTableDisplay(for: dayIndex, time: timeIndex)
    }
}

/* ###################################################################################################################################### */
// MARK: UIPageViewControllerDelegate Conformance
/* ###################################################################################################################################### */
extension VMF_DayTimeSearchViewController: UIPageViewControllerDelegate {
    /* ################################################################## */
    /**
     Called when a swipe transition is done. The only thing we do here, is reset our trackers.
     
     - parameter: The page view controller (ignored).
     - parameter didFinishAnimating: The animation is complete (ignored)
     - parameter previousViewControllers: A list of previous view controllers (also ignored)
     - parameter transitionCompleted: True, if the transition completed, and was not aborted.
     */
    func pageViewController(_: UIPageViewController, didFinishAnimating: Bool, previousViewControllers: [UIViewController], transitionCompleted inIsDone: Bool) {
        if inIsDone {
            if isNameSearchMode {
                weekdayModeSelectorSegmentedSwitch?.selectedSegmentIndex = (weekdayModeSelectorSegmentedSwitch?.numberOfSegments ?? 1) - 1
            } else {
                weekdayModeSelectorSegmentedSwitch?.selectedSegmentIndex = tableDisplayController?.dayIndex ?? 0
            }
        }
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
