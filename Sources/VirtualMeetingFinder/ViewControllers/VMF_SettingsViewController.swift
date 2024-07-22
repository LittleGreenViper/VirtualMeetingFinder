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
import RVS_Generic_Swift_Toolbox

/* ###################################################################################################################################### */
// MARK: - Settings View Controller -
/* ###################################################################################################################################### */
/**
 This displays the settings screen.
 */
class VMF_SettingsViewController: VMF_BaseViewController {
    /* ################################################################## */
    /**
     The bar button item that takes you to the about screen.
     */
    @IBOutlet weak var infoBarButtonItem: UIBarButtonItem?
    
    /* ################################################################## */
    /**
     The label for the filter Service meetings switch.
     */
    @IBOutlet weak var filterServiceMeetingsLabel: UILabel?
    
    /* ################################################################## */
    /**
     The switch, that, if on, means that Service meetings will be removed from the data.
     */
    @IBOutlet weak var filterServiceMeetingsSwitch: UISwitch?
    
    /* ################################################################## */
    /**
     This is displayed below the switch, and explains its utility.
     */
    @IBOutlet weak var filterServiceMeetingsExplainLabel: UILabel?
}

/* ###################################################################################################################################### */
// MARK: Callbacks
/* ###################################################################################################################################### */
extension VMF_SettingsViewController {
    /* ################################################################## */
    /**
     Called when either the label or switch to filter Service meetings is hit.
     
     - parameter inSender: The gesture recognizer or switch.
     */
    @IBAction func filterServiceMeetingsHit(_ inSender: NSObjectProtocol) {
        if let switcher = inSender as? UISwitch {   // If the switch, we execute it.
            VMF_AppDelegate.prefs.excludeServiceMeetings = switcher.isOn
            guard let searchController = VMF_AppDelegate.searchController,
                  let tableDisplayController = searchController.tableDisplayController
            else { return }
            
            let dayIndex = tableDisplayController.dayIndex
            let timeIndex = tableDisplayController.timeIndex
            guard let time = searchController.getTimeOf(dayIndex: dayIndex, timeIndex: timeIndex) else { return }
            searchController.reorganizeMeetings()
            searchController.openTo(dayIndex: dayIndex, time: time)
        } else {    // If the label, we toggle the switch, and send the value changed message (which calls us again).
            filterServiceMeetingsSwitch?.setOn(!(filterServiceMeetingsSwitch?.isOn ?? true), animated: true)
            filterServiceMeetingsSwitch?.sendActions(for: .valueChanged)
            selectionHaptic()
        }
    }
}

/* ###################################################################################################################################### */
// MARK: Base Class Overrides
/* ###################################################################################################################################### */
extension VMF_SettingsViewController {
    /* ################################################################## */
    /**
     Called when the view hierarchy has loaded and initialized.
     */
    override func viewDidLoad() {
        super.viewDidLoad()

        infoBarButtonItem?.accessibilityLabel = "SLUG-ACC-ABOUT-BUTTON-LABEL".accessibilityLocalizedVariant
        infoBarButtonItem?.accessibilityHint = "SLUG-ACC-ABOUT-BUTTON-HINT".accessibilityLocalizedVariant

        filterServiceMeetingsLabel?.textColor = .tintColor
        filterServiceMeetingsLabel?.text = filterServiceMeetingsLabel?.text?.localizedVariant
        filterServiceMeetingsSwitch?.isOn = VMF_AppDelegate.prefs.excludeServiceMeetings
        
        filterServiceMeetingsExplainLabel?.text = filterServiceMeetingsExplainLabel?.text?.localizedVariant
    }
}
