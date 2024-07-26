/**
 © Copyright 2020-2024, Recovrr.org, Inc.
 */

import MapKit
import RVS_UIKit_Toolbox

/* ###################################################################################################################################### */
// MARK: - Annotation Class -
/* ###################################################################################################################################### */
/**
 This handles the marker annotation for the main center.
 */
class VMF_MapAnnotation: NSObject, MKAnnotation {
    /* ################################################################## */
    /**
     The coordinate for this annotation.
     */
    let coordinate: CLLocationCoordinate2D
    
    /* ################################################################## */
    /**
     Default initializer.
     
     - parameter coordinate: the coordinate for this annotation.
     */
    init(coordinate inCoordinate: CLLocationCoordinate2D) {
        coordinate = inCoordinate
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
     
     - parameter annotation: The annotation instance.
     - parameter reuseIdentifier: The reuse ID.
     */
    override init(annotation inAnnotation: MKAnnotation?, reuseIdentifier inReuseID: String?) {
        super.init(annotation: inAnnotation, reuseIdentifier: inReuseID)
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
