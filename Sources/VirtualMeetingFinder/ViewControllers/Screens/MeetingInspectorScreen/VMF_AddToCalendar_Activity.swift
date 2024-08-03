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
import EventKitUI
import RVS_Generic_Swift_Toolbox

/* ###################################################################################################################################### */
// MARK: - Custom Activity Class Base -
/* ###################################################################################################################################### */
/**
 We can present a custom activity, that allows the user to add the meeting to their calendar.
 */
class VMF_Base_Activity: UIActivity {
     /* ################################################################## */
     /**
      The URL string, which is sent to Messages.
      */
     let meetingEvent: EKEvent
     
     /* ################################################################## */
     /**
      The controller that "owns" this instance.
      */
     weak var myController: VMF_MeetingInspectorViewController?
     
     /* ################################################################## */
     /**
      Initializer
      
      - parameter meetingEvent: The event for this activity.
      - parameter actionButton: The action button for the screen. We use it to anchor an iPad popover.
      */
     init(meetingEvent inMeetingEvent: EKEvent, myController inMyController: VMF_MeetingInspectorViewController?) {
          meetingEvent = inMeetingEvent
          myController = inMyController
     }
}

/* ###################################################################################################################################### */
// MARK: Base Class Overrides
/* ###################################################################################################################################### */
extension VMF_Base_Activity {
     /* ################################################################## */
     /**
      The basic category for this activity (an action line).
      */
     override class var activityCategory: UIActivity.Category { .action }
}

/* ###################################################################################################################################### */
// MARK: - Custom Add To Calendar Activity Class -
/* ###################################################################################################################################### */
/**
 We can present a custom activity, that allows the user to add the meeting to their calendar.
 */
class VMF_AddToCalendar_Activity: VMF_Base_Activity { }

/* ###################################################################################################################################### */
// MARK: Base Class Overrides
/* ###################################################################################################################################### */
extension VMF_AddToCalendar_Activity {
     /* ################################################################## */
     /**
      The title string for this activity.
      */
     override var activityTitle: String? { String(format: "SLUG-ADD-TO-CALENDAR".localizedVariant) }
     
     /* ################################################################## */
     /**
      The template image for the activity line.
      */
     override var activityImage: UIImage? { UIImage(systemName: "calendar.badge.plus") }
     
     /* ################################################################## */
     /**
      We have our own custom activity type.
      */
     override var activityType: UIActivity.ActivityType? { UIActivity.ActivityType("com.littlegreenviper.vmf.addToCalendar") }
     
     /* ################################################################## */
     /**
      We extract the event from the items, and return true.
      */
     override func canPerform(withActivityItems activityItems: [Any]) -> Bool {
          guard 1 < activityItems.count,
                activityItems[1] is EKEvent
          else { return false }
          
          return true
     }
     
     /* ################################################################## */
     /**
      This is the execution handler for the activity.
      */
     override func perform() {
          addReminderEvent()
     }
}

/* ###################################################################################################################################### */
// MARK: Instance Methods
/* ###################################################################################################################################### */
extension VMF_AddToCalendar_Activity {
     /* ################################################################## */
     /**
      This adds a reminder event for the next meeting start time.
      */
     func addReminderEvent() {
          /* ############################################################## */
          /**
           Completion proc for the permissions.
           
           - parameter inIsGranted: True, if permission was granted.
           - parameter inError: Any errors that occurred.
           */
          func calendarCompletion(_ inIsGranted: Bool, _ inError: Error?) {
               DispatchQueue.main.async { [weak self] in
                    guard nil == inError,
                          inIsGranted,
                          let self = self
                    else {
                         if !inIsGranted {
                              self?.displayPermissionsAlert(header: "SLUG-CALENDAR-PERM-ALERT-HEADER".localizedVariant, body: "SLUG-CALENDAR-PERM-ALERT-BODY".localizedVariant)
                         }
                         return
                    }
                    
                    let eventController = EKEventEditViewController()
                    eventController.event = meetingEvent
                    eventController.eventStore = self.myController?.eventStore
                    eventController.editViewDelegate = self
                    if .pad == self.myController?.traitCollection.userInterfaceIdiom,
                       let size = self.myController?.view?.bounds.size {
                         eventController.modalPresentationStyle = .popover
                         eventController.preferredContentSize = CGSize(width: size.width, height: size.height / 2)
                         eventController.popoverPresentationController?.sourceView = myController?.navigationController?.navigationBar
                         eventController.popoverPresentationController?.permittedArrowDirections = [.up]
                    }
                    
                    self.myController?.present(eventController, animated: true, completion: nil)
               }
          }
          
          if #available(iOS 17.0, *) {
               myController?.eventStore.requestWriteOnlyAccessToEvents(completion: calendarCompletion)
          } else {
               myController?.eventStore.requestAccess(to: EKEntityType.event, completion: calendarCompletion)
          }
     }
     
     /* ################################################################## */
     /**
      This displays an alert, for when permission is denied, and allows access to the settings.
      This can be called from non-main threads.
      
      - parameter header: The header. This can be a lo9calization slug.
      - parameter body: The message body. This can be a localization slug.
      */
     func displayPermissionsAlert(header inHeader: String, body inBody: String) {
          DispatchQueue.main.async {
               let style: UIAlertController.Style = .alert
               let alertController = UIAlertController(title: inHeader.localizedVariant, message: inBody.localizedVariant, preferredStyle: style)
               
               let okAction = UIAlertAction(title: "SLUG-CANCEL-BUTTON-TEXT".localizedVariant, style: .cancel, handler: nil)
               
               alertController.addAction(okAction)
               
               let settingsAction = UIAlertAction(title: "SETTINGS-ALERT-BUTTON-TEXT".localizedVariant, style: .default, handler: { _ in
                    VMF_AppDelegate.appDelegateInstance?.openMainSettings()
               })
               
               alertController.addAction(settingsAction)
               
               self.myController?.present(alertController, animated: true, completion: nil)
          }
     }
}

/* ###################################################################################################################################### */
// MARK: EKEventEditViewDelegate Conformance
/* ###################################################################################################################################### */
extension VMF_AddToCalendar_Activity: EKEventEditViewDelegate {
     /* ################################################################## */
     /**
      Called when the event kit has completed with an action to add the reminder to the calendar.
      
      - parameter inController: The controller we're talking about.
      - parameter didCompleteWith: The even action that completed.
      */
     func eventEditViewController(_ inController: EKEventEditViewController, didCompleteWith inAction: EKEventEditViewAction) {
          inController.dismiss(animated: true, completion: nil)
     }
}
