//
//  MockCharacterRepository.swift
//  iOS-RehearsalTests
//
//  Created by Rubén Suárez on 14/06/26.
//

import Foundation
@testable import iOS_Rehearsal

/// Un Proxy de pruebas que implementa `CharacterRepositoryProtocol` para simular
/// la persistencia en CoreData y las peticiones de red de forma síncrona y en memoria.
public final class MockCharacterRepository: CharacterRepositoryProtocol, @unchecked Sendable {
    // Control de errores
    public var shouldThrowError = false
    public var errorToThrow: Error = NSError(domain: "MockError", code: 0, userInfo: nil)
    
    // Datos simulados
    public var mockCharacters: [Character] = []
    public var pageSize = 20
    public var favoriteStates: [Int: Bool] = [:]
    public var watchedEpisodes: [String: Bool] = [:]
    public var mockEpisodes: [Episode] = []
    
    // Registro de llamadas para aserciones (Asserts)
    public var fetchCharactersCalledCount = 0
    public var fetchCharactersLastParameters: (page: Int, name: String?, status: String?, species: String?)?
    
    public var toggleFavoriteCalledCount = 0
    public var toggleFavoriteLastId: Int?
    
    public var getFavoritesCalledCount = 0
    
    public var fetchEpisodeDetailsCalledCount = 0
    public var fetchEpisodeDetailsLastUrls: [String]?
    
    public var markEpisodeWatchedCalledCount = 0
    public var markEpisodeWatchedLastParameters: (episodeUrl: String, isWatched: Bool)?
    
    public init() {}
    
    public func fetchCharacters(
        page: Int,
        name: String?,
        status: String?,
        species: String?
    ) async throws -> [Character] {
        fetchCharactersCalledCount += 1
        fetchCharactersLastParameters = (page, name, status, species)
        
        if shouldThrowError {
            throw errorToThrow
        }
        
        // Filtrado básico en memoria
        var filtered = mockCharacters
        if let name = name, !name.isEmpty {
            filtered = filtered.filter { $0.name.localizedCaseInsensitiveContains(name) }
        }
        if let status = status, !status.isEmpty {
            filtered = filtered.filter { $0.status.rawValue.localizedCaseInsensitiveCompare(status) == .orderedSame }
        }
        if let species = species, !species.isEmpty {
            filtered = filtered.filter { $0.species.localizedCaseInsensitiveContains(species) }
        }
        
        // Paginación ficticia
        let startIndex = (page - 1) * pageSize
        if startIndex >= filtered.count {
            return []
        }
        let endIndex = min(startIndex + pageSize, filtered.count)
        return Array(filtered[startIndex..<endIndex])
    }
    
    public func toggleFavorite(characterId: Int) async throws -> Bool {
        toggleFavoriteCalledCount += 1
        toggleFavoriteLastId = characterId
        
        if shouldThrowError {
            throw errorToThrow
        }
        
        let currentState = favoriteStates[characterId] ?? false
        let newState = !currentState
        favoriteStates[characterId] = newState
        
        // Actualizar en el array mockCharacters si existe
        if let index = mockCharacters.firstIndex(where: { $0.id == characterId }) {
            mockCharacters[index].isFavorite = newState
        }
        
        return newState
    }
    
    public func getFavorites() async throws -> [Character] {
        getFavoritesCalledCount += 1
        
        if shouldThrowError {
            throw errorToThrow
        }
        
        return mockCharacters.filter { favoriteStates[$0.id] == true }
    }
    
    public func fetchEpisodeDetails(episodeUrls: [String]) async throws -> [Episode] {
        fetchEpisodeDetailsCalledCount += 1
        fetchEpisodeDetailsLastUrls = episodeUrls
        
        if shouldThrowError {
            throw errorToThrow
        }
        
        return mockEpisodes.filter { episodeUrls.contains($0.url) }.map { episode in
            var updated = episode
            updated.isWatched = watchedEpisodes[episode.url] ?? false
            return updated
        }
    }
    
    public func markEpisodeWatched(episodeUrl: String, isWatched: Bool) async throws {
        markEpisodeWatchedCalledCount += 1
        markEpisodeWatchedLastParameters = (episodeUrl, isWatched)
        
        if shouldThrowError {
            throw errorToThrow
        }
        
        watchedEpisodes[episodeUrl] = isWatched
    }
}
