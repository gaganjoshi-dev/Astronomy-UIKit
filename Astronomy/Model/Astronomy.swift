//
//  Astronomy.swift
//  Astronomy
//
//  Created by gagan joshi on 2024-10-12.
//

import UIKit

struct Astronomy: Codable {
    let copyright: String?
    let date: String
    let explanation: String
    let hdurl: String?
    let mediaType: String
    let serviceVersion: String
    let title: String
    let url: String
    var image: UIImage? 
    
    enum CodingKeys: String, CodingKey {
        case copyright
        case date
        case explanation
        case hdurl
        case mediaType = "media_type"
        case serviceVersion = "service_version"
        case title
        case url
    }
}

/*
       "copyright": "Yuri Beletsky",
       "date": "2024-10-11",
       "explanation": "The second solar eclipse of 2024 began in the Pacific. On October 2nd the Moon's shadow swept from west to east, with an annular eclipse visible along a narrow antumbral shadow path tracking mostly over ocean, making its only major landfall near the southern tip of South America, and then ending in the southern Atlantic. The dramatic total annular eclipse phase is known to some as a ring of fire. Also tracking across islands in the southern Pacific, the Moon's antumbral shadow grazed Easter Island allowing denizens to follow all phases of the annular eclipse. Framed by palm tree leaves this clear island view is a stack of two images, one taken with and one taken without a solar filter near the moment of the maximum annular phase. The New Moon's silhouette appears just off center, though still engulfed by the bright disk of the active Sun.   Growing Gallery: Global aurora during October 10/11, 2024",
       "hdurl": "https://apod.nasa.gov/apod/image/2410/eclipse_02.jpg",
       "media_type": "image",
       "service_version": "v1",
       "title": "Ring of Fire over Easter Island",
       "url": "https://apod.nasa.gov/apod/image/2410/eclipse_02_1024.jpg"
*/
