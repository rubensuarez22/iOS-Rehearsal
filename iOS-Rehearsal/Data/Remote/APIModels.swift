//
//  APIModels.swift
//  iOS-Rehearsal
//
//  Created by Rubén Suárez on 14/06/26.
//

import Foundation

// MARK: - API Response Wrapper
public struct CharacterResponseDTO: Decodable {
    public let info: PageInfoDTO
    public let results: [CharacterDTO]
}

public struct PageInfoDTO: Decodable {
    public let count: Int
    public let pages: Int
    public let next: String?
    public let prev: String?
}

// MARK: - Character DTO
public struct CharacterDTO: Decodable {
    public let id: Int
    public let name: String
    public let status: String
    public let species: String
    public let type: String
    public let gender: String
    public let image: String
    public let url: String
    public let origin: LocationInfoDTO
    public let location: LocationInfoDTO
    public let episode: [String]
}

public struct LocationInfoDTO: Decodable {
    public let name: String
    public let url: String
}

// MARK: - Episode DTO
public struct EpisodeDTO: Decodable {
    public let id: Int
    public let name: String
    public let air_date: String
    public let episode: String
    public let characters: [String]
    public let url: String
    public let created: String
}
