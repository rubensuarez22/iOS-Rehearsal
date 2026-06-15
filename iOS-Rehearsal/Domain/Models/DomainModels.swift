//
//  DomainModels.swift
//  iOS-Rehearsal
//
//  Created by Rubén Suárez on 14/06/26.
//

import Foundation

// MARK: - Character Status
public enum CharacterStatus: String, CaseIterable {
    case alive = "Alive"
    case dead = "Dead"
    case unknown = "unknown"
}

// MARK: - Character Model
public struct Character: Identifiable, Equatable, Hashable {
    public let id: Int
    public let name: String
    public let status: CharacterStatus
    public let species: String
    public let type: String
    public let gender: String
    public let image: String
    public let url: String
    public let originName: String
    public let locationName: String
    public let locationUrl: String
    public let episodeUrls: [String]
    public var isFavorite: Bool
    public var latitude: Double
    public var longitude: Double

    nonisolated public init(
        id: Int,
        name: String,
        status: CharacterStatus,
        species: String,
        type: String,
        gender: String,
        image: String,
        url: String,
        originName: String,
        locationName: String,
        locationUrl: String,
        episodeUrls: [String],
        isFavorite: Bool = false,
        latitude: Double = 0.0,
        longitude: Double = 0.0
    ) {
        self.id = id
        self.name = name
        self.status = status
        self.species = species
        self.type = type
        self.gender = gender
        self.image = image
        self.url = url
        self.originName = originName
        self.locationName = locationName
        self.locationUrl = locationUrl
        self.episodeUrls = episodeUrls
        self.isFavorite = isFavorite
        self.latitude = latitude
        self.longitude = longitude
    }
}

// MARK: - Episode Model
public struct Episode: Identifiable, Equatable, Hashable {
    public let id: Int
    public let name: String
    public let airDate: String
    public let episode: String
    public let characters: [String]
    public let url: String
    public let created: String
    public var isWatched: Bool

    nonisolated public init(
        id: Int,
        name: String,
        airDate: String,
        episode: String,
        characters: [String],
        url: String,
        created: String,
        isWatched: Bool = false
    ) {
        self.id = id
        self.name = name
        self.airDate = airDate
        self.episode = episode
        self.characters = characters
        self.url = url
        self.created = created
        self.isWatched = isWatched
    }
}

// MARK: - Location Model
public struct LocationModel: Identifiable, Equatable, Hashable {
    public let id: Int
    public let name: String
    public let type: String
    public let dimension: String
    public let residents: [String]
    public let url: String
    public let created: String

    nonisolated public init(
        id: Int,
        name: String,
        type: String,
        dimension: String,
        residents: [String],
        url: String,
        created: String
    ) {
        self.id = id
        self.name = name
        self.type = type
        self.dimension = dimension
        self.residents = residents
        self.url = url
        self.created = created
    }
}
