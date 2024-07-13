/*
 © Copyright 2024, Little Green Viper Software Development LLC
 LICENSE:
 
 MIT License
 
 Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentationmap
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
// MARK: UIPageViewControllerDataSource Conformance
/* ###################################################################################################################################### */
extension VMF_MainViewController: UIPageViewControllerDataSource {
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
        
        var dayIndex = oldViewController.dayIndex
        var timeIndex = oldViewController.timeIndex
        timeIndex -= 1

        if 0 == dayIndex || 0 > timeIndex {
            if 0 == dayIndex {
                dayIndex = 7
            } else {
                dayIndex -= 1
                if 0 > dayIndex {
                    dayIndex = 7
                }
            }
            timeIndex = getDailyMeetings(for: mapWeekday(dayIndex)).keys.count - 1
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
extension VMF_MainViewController: UIPageViewControllerDelegate {
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
                let newIndex = tableDisplayController?.dayIndex ?? 0
                let oldIndex = weekdayModeSelectorSegmentedSwitch?.selectedSegmentIndex ?? 0
                weekdayModeSelectorSegmentedSwitch?.selectedSegmentIndex = tableDisplayController?.dayIndex ?? 0
                if oldIndex != newIndex {
                    successHaptic()
                }
                
                if let tableDisplayController = tableDisplayController {
                    updateThermometer(tableDisplayController)
                }
            }
            
            timeDayDisplayLabel?.text = (tableDisplayController as? UIViewController)?.title
        }
    }
}

/* ###################################################################################################################################### */
// MARK: UIPickerViewDataSource Conformance
/* ###################################################################################################################################### */
extension VMF_MainViewController: UIPickerViewDataSource {
    /* ################################################################## */
    /**
     This returns the number of components in the picker view.
     
     - parameter in: The picker view (ignored).
     - returns: 2 (always)
     */
    func numberOfComponents(in: UIPickerView) -> Int { 2 }
    
    /* ################################################################## */
    /**
     This returns the number of rows in each component.
     
     - parameter: The picker view.
     - parameter numberOfRowsInComponent: The 0-based component index. Component 0 is the weekday, and Component 1, is the time slots for that weekday.
     
     - returns: 7 (Component 0), or the number of time slots for the selected weekday (usually around 70).
     */
    func pickerView(_ inPickerView: UIPickerView, numberOfRowsInComponent inComponent: Int) -> Int {
        guard !isNameSearchMode else { return 0 }
        
        let ret = 1 == inComponent ? getDailyMeetings(for: unMapWeekday(inPickerView.selectedRow(inComponent: 0) + 1)).count : 7
        
        return ret
    }
}

/* ###################################################################################################################################### */
// MARK: UIPickerViewDelegate Conformance
/* ###################################################################################################################################### */
extension VMF_MainViewController: UIPickerViewDelegate {
    /* ################################################################## */
    /**
     This returns the title for the selected row, as a label.
     
     - parameter inPickerView: The picker view.
     - parameter titleForRow: The 0-based row index.
     - parameter forComponent: The 0-based component index.
     - parameter reusing: Any previously allocated view, to be reused.
     
     - returns: a view (a label), with the title for the indicated row.
     */
    func pickerView(_ inPickerView: UIPickerView, viewForRow inRow: Int, forComponent inComponent: Int, reusing inReusing: UIView?) -> UIView {
        let ret = inReusing as? UILabel ?? UILabel()
        ret.adjustsFontSizeToFitWidth = true
        ret.minimumScaleFactor = 0.5
        
        if !isNameSearchMode {
            if 0 == inComponent {
                ret.text = Calendar.current.standaloneWeekdaySymbols[unMapWeekday(inRow + 1) - 1]
            } else {
                let dayIndex = unMapWeekday(inPickerView.selectedRow(inComponent: 0) + 1)
                if let time = getTimeOf(dayIndex: dayIndex, timeIndex: inRow) {
                    let hour = time / 100
                    let minute = time - (hour * 100)
                    let dateComponents = DateComponents(hour: hour, minute: minute)
                    let date = Calendar.current.date(from: dateComponents)
                    let string = date?.localizedTime
                    ret.text = string
                }
            }
        }
        
        if inRow == inPickerView.selectedRow(inComponent: inComponent) {
            ret.textColor = .systemBackground
            ret.backgroundColor = .label
        } else {
            ret.backgroundColor = .clear
            ret.textColor = .tintColor
        }
        
        ret.textAlignment = .center

        return ret
    }
    
    /* ################################################################## */
    /**
     Get the width of a component.
     
     - parameter: The picker view.
     - parameter widthForComponent: The 0-based component index.
     - returns: The width, in display units, of the component.
     */
    func pickerView(_: UIPickerView, widthForComponent: Int) -> CGFloat { Self.pickerViewComponentWidthInDisplayUnits }
    
    /* ################################################################## */
    /**
     Called when a row is selected in the picker.
     
     - parameter inPickerView: The picker view.
     - parameter didSelectRow: The 0-based row index.
     - parameter inComponent: The 0-based component index.
     */
    func pickerView(_ inPickerView: UIPickerView, didSelectRow inRow: Int, inComponent: Int) {
        if 0 == inComponent {
            // This whackiness, is because we want to try to set the time index to be as close as possible to the last one.
            guard let originalDayIndex = tableDisplayController?.dayIndex,
                  var timeIndex = tableDisplayController?.timeIndex,
                  let originalTime = getTimeOf(dayIndex: originalDayIndex, timeIndex: timeIndex)
            else { return }
         
            timeIndex = getNearestIndex(dayIndex: inRow + 1, time: originalTime)
            guard let time = getTimeOf(dayIndex: inRow + 1, timeIndex: timeIndex) else { return }
            
            inPickerView.reloadComponent(1)
            inPickerView.selectRow(timeIndex, inComponent: 1, animated: false)
            openTo(dayIndex: inRow + 1, time: time)
        } else {
            let dayIndex = unMapWeekday(inPickerView.selectedRow(inComponent: 0) + 1)
            guard let time = getTimeOf(dayIndex: dayIndex, timeIndex: inRow) else { return }
            openTo(dayIndex: dayIndex, time: time)
        }
        
        inPickerView.reloadAllComponents()
    }
}
