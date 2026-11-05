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

import UIKit

/* ###################################################################################################################################### */
// MARK: Time Slot Paging
/* ###################################################################################################################################### */
extension VMF_MainViewController {
     /**
      Resolves Now to the latest available start at or before the current local time.
      Regular pages move one slot at a time, skipping empty weekdays and wrapping the week.
      Now is entered explicitly from the popover, rather than appearing between time slots.
      */
     func adjacentTimeSlot(fromDay inDay: Int, timeIndex inIndex: Int, forward inIsForward: Bool) -> (dayIndex: Int, timeIndex: Int)? {
          if inDay == 0 {
               let now = nowIs
               guard (1...7).contains(now.weekday) else { return nil }
               for offset in 0...7 {
                    let day = (now.weekday - 1 - offset + 7) % 7 + 1
                    let times = getDailyMeetings(for: day).keys.sorted()
                    let index = offset == 0 ? times.lastIndex(where: { $0 <= now.currentIntegerTime }) : times.indices.last
                    if let index = index { return (day, index) }
               }
               return nil
          }

          guard (1...7).contains(inDay) else { return nil }
          let step = inIsForward ? 1 : -1
          let nextIndex = inIndex + step
          if (0..<getDailyMeetings(for: inDay).count).contains(nextIndex) {
               return (inDay, nextIndex)
          }
          for offset in 1...7 {
               let day = (inDay - 1 + offset * step + 7) % 7 + 1
               let count = getDailyMeetings(for: day).count
               if count > 0 { return (day, inIsForward ? 0 : count - 1) }
          }
          return nil
     }
}

/* ###################################################################################################################################### */
// MARK: UIPageViewControllerDataSource Conformance
/* ###################################################################################################################################### */
extension VMF_MainViewController: UIPageViewControllerDataSource {
     /// Supplies the previous time-slot page, or the latest start before now when leaving Now.
     func pageViewController(_: UIPageViewController, viewControllerBefore inController: UIViewController) -> UIViewController? {
          guard !isNameSearchMode,
                let page = inController as? VMF_EmbeddedTableController,
                let slot = adjacentTimeSlot(fromDay: page.dayIndex, timeIndex: page.timeIndex, forward: false) else { return nil }
          return getTableDisplay(for: slot.dayIndex, time: slot.timeIndex)
     }

     /// Supplies the next time-slot page, using the same Now exit rule as backward paging.
     func pageViewController(_: UIPageViewController, viewControllerAfter inController: UIViewController) -> UIViewController? {
          guard !isNameSearchMode,
                let page = inController as? VMF_EmbeddedTableController,
                let slot = adjacentTimeSlot(fromDay: page.dayIndex, timeIndex: page.timeIndex, forward: true) else { return nil }
          return getTableDisplay(for: slot.dayIndex, time: slot.timeIndex)
     }
}

/* ###################################################################################################################################### */
// MARK: UIPageViewControllerDelegate Conformance
/* ###################################################################################################################################### */
extension VMF_MainViewController: UIPageViewControllerDelegate {
     /** Commits only a completed swipe, keeping the navigation title on the visible page. */
     func pageViewController(_ inController: UIPageViewController, didFinishAnimating: Bool, previousViewControllers inPrevious: [UIViewController], transitionCompleted inIsDone: Bool) {
          guard inIsDone,
                let page = inController.viewControllers?.first as? VMF_EmbeddedTableController else { return }
          if (inPrevious.first as? VMF_EmbeddedTableController)?.dayIndex != page.dayIndex {
               successHaptic()
          }
          tableDisplayController = page
          if inPrevious.contains(where: { ($0 as? VMF_EmbeddedTableController)?.dayIndex == 0 }) {
               // Let UIKit finish the transition before discarding its cached Now neighbor.
               DispatchQueue.main.async { [weak self, weak inController] in
                    guard let self = self, let controller = inController,
                          controller.viewControllers?.first === page, !self.isNameSearchMode else { return }
                    controller.dataSource = nil
                    controller.dataSource = self
               }
          }
     }
}
