//
//  DroppablePin.swift
//  pixel-city_learning
//
//  Created by Chuck on 2018/5/11.
//  Copyright © 2018年 Chuck. All rights reserved.
//

import UIKit
import MapKit


class DroppablePin: NSObject, MKAnnotation {
    //MKAnnotation is used for related contents with map location
    
    dynamic var coordinate: CLLocationCoordinate2D
    var identifier: String

    init(coordiante: CLLocationCoordinate2D, identifier: String) {
        self.coordinate = coordiante
        self.identifier = identifier
        super.init()
    }

}
