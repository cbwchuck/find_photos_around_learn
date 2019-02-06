//
//  Constants.swift
//  pixel-city_learning
//
//  Created by Chuck on 2018/5/12.
//  Copyright © 2018年 Chuck. All rights reserved.
//

import Foundation

/* apiKey of flickr goes here */
let apiKey = ""
let numberOfPhotsPerPage = 40
let popVCIdentifier = "PopVC"

func getFlickrUrl (forKey key: String, forAnnotation annotation: DroppablePin, andNumberOfPhots number: Int) -> String {
    return "https://api.flickr.com/services/rest/?method=flickr.photos.search&api_key=\(apiKey)&lat=\(annotation.coordinate.latitude)&lon=\(annotation.coordinate.longitude)&radius=1&radius_units=mi&per_page=\(number)&format=json&nojsoncallback=1"
}
