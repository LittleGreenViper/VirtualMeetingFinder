/*
 © Copyright 2020-2024, Recovrr.org, Inc.
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

import MapKit
import RVS_UIKit_Toolbox

/* ###################################################################################################################################### */
// MARK: - Annotation Class -
/* ###################################################################################################################################### */
/**
 A hybrid meeting's coordinate, name, and optional street address for the inspector map.
 */
class VMF_MapAnnotation: NSObject, MKAnnotation {
     /* ################################################################## */
     /**
      The coordinate for this annotation.
      */
     let coordinate: CLLocationCoordinate2D

     /// The meeting name announced by MapKit.
     let title: String?

     /// The in-person address, when supplied by the meeting record.
     let subtitle: String?

     /* ################################################################## */
     /**
      Default initializer.

      - parameter inCoordinate: the coordinate for this annotation.
      - parameter inTitle: The meeting name.
      - parameter inSubtitle: The in-person address.
      */
     init(coordinate inCoordinate: CLLocationCoordinate2D, title inTitle: String? = nil, subtitle inSubtitle: String? = nil) {
          coordinate = inCoordinate
          title = inTitle
          subtitle = inSubtitle
     }
}

/* ###################################################################################################################################### */
// MARK: - Marker Class -
/* ###################################################################################################################################### */
/**
 This handles our map marker.
 */
class VMF_MapMarker: MKAnnotationView {
     /* ################################################################## */
     /**
      Marker maximum dimension, in Display Units
      */
     static let sMarkerSizeInDisplayUnits = CGFloat(40)

     /* ################################################################## */
     /**
      The reuse ID for this view class.
      */
     static let reuseID: String = "VMF_MapMarker"

     /* ################################################################## */
     /**
      We override, so we can set the image.

      - parameter inAnnotation: The annotation instance.
      - parameter inReuseID: The reuse ID.
      */
     override init(annotation inAnnotation: MKAnnotation?, reuseIdentifier inReuseID: String?) {
          super.init(annotation: inAnnotation, reuseIdentifier: inReuseID)
          isAccessibilityElement = true
          accessibilityLabel = inAnnotation?.title ?? "SLUG-IN-PERSON-HEADER".localizedVariant
          accessibilityValue = inAnnotation?.subtitle ?? nil
          accessibilityHint = "SLUG-ACC-MAP-HINT".localizedVariant
          guard let imageTemp = UIImage(named: "Marker-Single")?.withRenderingMode(.alwaysOriginal).resized(toMaximumSize: Self.sMarkerSizeInDisplayUnits) else { return }
          image = imageTemp
          centerOffset = CGPoint(x: 0, y: imageTemp.size.height / -2) // Bottom, center.
     }

     /* ################################################################## */
     /**
      Required NSCoding conformance

      - parameter inDecoder: The decoder instance.
      */
     required init?(coder inDecoder: NSCoder) {
          super.init(coder: inDecoder)
     }
}

/* ###################################################################################################################################### */
// MARK: Computed Instance Properties
/* ###################################################################################################################################### */
extension VMF_MapMarker {
     /* ################################################################## */
     /**
      The marker coordinate is the annotation coordinate
      */
     var coordinate: CLLocationCoordinate2D { annotation?.coordinate ?? kCLLocationCoordinate2DInvalid }
}
