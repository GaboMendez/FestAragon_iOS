//
//  Event.swift
//  FestAragon
//
//  Created by Gabriel Mendez Reyes on 14/1/26.
//

import Foundation

struct Event: Identifiable, Codable {
    let id: UUID
    let title: String
    let description: String
    let date: Date
    let category: EventCategory
    let location: String
    let imageURL: String?
    let price: Double
    let isPast: Bool
    var isFavorite: Bool
    
    init(
        id: UUID = UUID(),
        title: String,
        description: String,
        date: Date,
        category: EventCategory,
        location: String,
        imageURL: String? = nil,
        price: Double = 0.0,
        isPast: Bool = false,
        isFavorite: Bool = false
    ) {
        self.id = id
        self.title = title
        self.description = description
        self.date = date
        self.category = category
        self.location = location
        self.imageURL = imageURL
        self.price = price
        self.isPast = isPast
        self.isFavorite = isFavorite
    }
}

enum EventCategory: String, Codable, CaseIterable {
    case music = "MÚSICA"
    case cultural = "CULTURAL"
    case infantil = "INFANTIL"
    case traditional = "TRADICIONAL"
    
    var displayName: String {
        self.rawValue
    }
}
