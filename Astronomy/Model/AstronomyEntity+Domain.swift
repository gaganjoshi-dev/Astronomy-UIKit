//
//  AstronomyEntity+Domain.swift
//  Astronomy
//

import Foundation

extension AstronomyEntity {
    func update(from astronomy: Astronomy, fetchedAt: Date = Date()) {
        copyright = astronomy.copyright
        date = astronomy.date
        explanation = astronomy.explanation
        hdurl = astronomy.hdurl
        mediaType = astronomy.mediaType
        serviceVersion = astronomy.serviceVersion
        title = astronomy.title
        url = astronomy.url
        lastFetched = fetchedAt
    }

    func toDomain() -> Astronomy {
        Astronomy(
            copyright: copyright,
            date: date ?? "",
            explanation: explanation ?? "",
            hdurl: hdurl,
            mediaType: mediaType ?? MediaType.image.rawValue,
            serviceVersion: serviceVersion ?? "v1",
            title: title ?? "",
            url: url ?? ""
        )
    }
}
