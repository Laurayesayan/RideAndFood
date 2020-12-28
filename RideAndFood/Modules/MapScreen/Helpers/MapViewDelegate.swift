//
//  MapViewDelegate.swift
//  RideAndFood
//
//  Created by Nikita Gundorin on 26.10.2020.
//  Copyright © 2020 skillbox. All rights reserved.
//

import MapKit

class MapViewDelegate: NSObject, MKMapViewDelegate {
    
    var mapViewCenterUpdatedCollback: ((CLPlacemark?) -> Void)?
    
    func mapView(_ mapView: MKMapView, regionDidChangeAnimated animated: Bool) {
        lookUpCurrentLocation(location: CLLocation(latitude: mapView.centerCoordinate.latitude,
                                                   longitude: mapView.centerCoordinate.longitude))
    }
    
//    func mapView(_ mapView: MKMapView, viewFor annotation: MKAnnotation) -> MKAnnotationView? {
//        let annotationView = mapView.dequeueReusableAnnotationView(withIdentifier: "annotationView")
//            ?? MKAnnotationView()
//        
//        guard annotation is CarAnnotation else {
//            annotationView.image = UIImage(named: "")
//            return annotationView
//        }
//        
//        annotationView.image = UIImage(named: "Car")
//
//        return annotationView
//    }
    
    private func lookUpCurrentLocation(location: CLLocation) {
        
        let geocoder = CLGeocoder()
        geocoder.reverseGeocodeLocation(location) { [weak self] (placemarks, error) in
            guard let mapViewCenterUpdatedCollback = self?.mapViewCenterUpdatedCollback else { return }
            if error == nil {
                let firstLocation = placemarks?[0]
                mapViewCenterUpdatedCollback(firstLocation)
            }
            else {
                mapViewCenterUpdatedCollback(nil)
            }
        }
    }
}

protocol MapViewCurrentAddressDelegate: class{
    func currentAddressChanged(newAddress: String?)
}
