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
// MARK: - Attendance Tab View Controller -
/* ###################################################################################################################################### */
/**
 This is the main view controller for the attended meetings tab.
 */
class VMF_AttendanceViewController: VMF_BaseViewController {
    /* ################################################################## */
    /**
     This tracks the current embedded table controller.
     */
    var tableDisplayController: VMF_EmbeddedTableControllerProtocol?
}

/* ###################################################################################################################################### */
// MARK: Computed Properties
/* ###################################################################################################################################### */
extension VMF_AttendanceViewController {
    /* ################################################################## */
    /**
     The meetings we are tracking.
     */
    var meetings: [MeetingInstance] {
        VMF_AppDelegate.virtualService?.meetingsThatIAttend.sorted { a, b in
            if a.isInProgress,
               !b.isInProgress {
                return true
            } else if b.isInProgress,
                      !a.isInProgress {
                return false
            } else if a.nextDate < b.nextDate {
                return true
            } else if b.nextDate < a.nextDate {
                return false
            } else {
                return a.meeting.name < b.meeting.name
            }
        }.map { $0.meeting } ?? []
    }
}

/* ###################################################################################################################################### */
// MARK: Base Class Overrides
/* ###################################################################################################################################### */
extension VMF_AttendanceViewController {
    /* ################################################################## */
    /**
     Called when the view hierarchy loads.
     */
    override func viewDidLoad() {
        super.viewDidLoad()
        navigationItem.title = "SLUG-TAB-1-TITLE".localizedVariant
    }
    
    /* ################################################################## */
    /**
     Called just before the view is to disappear.
     
     - parameter inIsAnimated: True, if the disappearance is animated.
     */
    override func viewWillDisappear(_ inIsAnimated: Bool) {
        super.viewWillDisappear(inIsAnimated)
        
        if isMovingFromParent {
            hardImpactHaptic()
        }
    }

    /* ################################################################## */
    /**
     Called before populating the table
     
     - parameter for: The segue object being executed.
     - parameter sender: Any associated data (ignored).
     */
    override func prepare(for inSegue: UIStoryboardSegue, sender: Any?) {
        guard let destination = inSegue.destination as? VMF_EmbeddedTableController else { return }
        tableDisplayController = destination
        destination.myController = self
        destination.meetings = meetings
    }
}

/* ###################################################################################################################################### */
// MARK: Base Class Overrides
/* ###################################################################################################################################### */
extension VMF_AttendanceViewController: VMF_MasterTableControllerProtocol {
    /* ################################################################## */
    /**
     This does nothing
     */
    func updateThermometer(_ inTablePage: VMF_EmbeddedTableControllerProtocol? = nil) { }
}
