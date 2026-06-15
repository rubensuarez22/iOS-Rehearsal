//
//  CharacterRepository.swift
//  iOS-Rehearsal
//
//  Created by Rubén Suárez on 14/06/26.
//

import Foundation
import CoreData

// MARK: - Character Repository
public final class CharacterRepository: CharacterRepositoryProtocol {
    private let apiClient: APIClientProtocol
    private let container: NSPersistentContainer
    private var episodeCache: [String: Episode] = [:]
    private let cacheLock = NSLock()
    
    public init(apiClient: APIClientProtocol, container: NSPersistentContainer) {
        self.apiClient = apiClient
        self.container = container
    }
    
    // MARK: - Cache Helpers Privados (Thread-safe)
    
    private func getCachedEpisode(for url: String) -> Episode? {
        cacheLock.lock()
        defer { cacheLock.unlock() }
        return episodeCache[url]
    }
    
    private func setCachedEpisode(_ episode: Episode, for url: String) {
        cacheLock.lock()
        defer { cacheLock.unlock() }
        if episodeCache.count > 250 {
            episodeCache.removeAll() // Evita el crecimiento ilimitado de memoria (evicción)
        }
        episodeCache[url] = episode
    }
    
    // MARK: - CharacterRepositoryProtocol
    
    public func fetchCharacters(
        page: Int,
        name: String?,
        status: String?,
        species: String?
    ) async throws -> [Character] {
        do {
            // 1. Intentamos descargar la información fresca de internet
            let responseDTO = try await apiClient.fetchCharacters(
                page: page,
                name: name,
                status: status,
                species: species
            )
            
            var characters: [Character] = []
            
            let backgroundContext = container.newBackgroundContext()
            backgroundContext.mergePolicy = NSMergePolicy.mergeByPropertyObjectTrump
            
            try await backgroundContext.perform {
                // Optimizamos con una sola búsqueda (Batch Fetching)
                let ids = responseDTO.results.map { Int64($0.id) }
                let request = CDCharacter.fetchRequest()
                request.predicate = NSPredicate(format: "id IN %@", ids)
                
                let existingCharacters = (try? backgroundContext.fetch(request)) ?? []
                let existingDict = Dictionary(uniqueKeysWithValues: existingCharacters.map { ($0.id, $0) })
                
                for dto in responseDTO.results {
                    let existingCharacter = existingDict[Int64(dto.id)]
                    let isFav = existingCharacter?.isFavorite ?? false
                    
                    let domainChar = dto.toDomain(isFavorite: isFav)
                    
                    let cdCharacter = existingCharacter ?? CDCharacter(context: backgroundContext)
                    cdCharacter.id = Int64(domainChar.id)
                    cdCharacter.name = domainChar.name
                    cdCharacter.status = domainChar.status.rawValue
                    cdCharacter.species = domainChar.species
                    cdCharacter.type = domainChar.type
                    cdCharacter.gender = domainChar.gender
                    cdCharacter.image = domainChar.image
                    cdCharacter.url = domainChar.url
                    cdCharacter.originName = domainChar.originName
                    cdCharacter.locationName = domainChar.locationName
                    cdCharacter.locationUrl = domainChar.locationUrl
                    cdCharacter.isFavorite = domainChar.isFavorite
                    cdCharacter.latitude = domainChar.latitude
                    cdCharacter.longitude = domainChar.longitude
                    
                    do {
                        let data = try JSONEncoder().encode(domainChar.episodeUrls)
                        cdCharacter.episodeUrlsData = data
                    } catch {
                        AppLogger.error("Error al codificar URLs de episodios para personaje \(domainChar.id)", category: .database, error: error)
                    }
                    
                    characters.append(domainChar)
                }
                
                if backgroundContext.hasChanges {
                    try backgroundContext.save()
                }
            }
            
            return characters
            
        } catch {
            // Solo usamos el fallback a CoreData para errores de red (URLError o APIError)
            let isNetworkError = error is URLError || error is APIError
            
            if !isNetworkError {
                throw error // Re-lanzar errores que no son de red (ej: fallos de CoreData save, CancellationError, etc.)
            }
            
            if let apiError = error as? APIError, case .rateLimited = apiError {
                AppLogger.error("Error de red en fetchCharacters debido a Rate Limiting (HTTP 429 Too Many Requests), usando caché de CoreData como fallback tolerante a fallos", category: .network, error: error)
            } else {
                AppLogger.error("Error de red en fetchCharacters, usando caché de CoreData", category: .network, error: error)
            }
            
            let backgroundContext = container.newBackgroundContext()
            return try await backgroundContext.perform {
                let request = CDCharacter.fetchRequest()
                var predicates: [NSPredicate] = []
                
                // Filtramos localmente igual que en la API si el usuario especificó filtros
                if let name = name, !name.isEmpty {
                    predicates.append(NSPredicate(format: "name CONTAINS[cd] %@", name))
                }
                if let status = status, !status.isEmpty {
                    predicates.append(NSPredicate(format: "status ==[cd] %@", status))
                }
                if let species = species, !species.isEmpty {
                    predicates.append(NSPredicate(format: "species CONTAINS[cd] %@", species))
                }
                
                if !predicates.isEmpty {
                    request.predicate = NSCompoundPredicate(andPredicateWithSubpredicates: predicates)
                }
                
                // Ordenamos por ID para mantener consistencia
                request.sortDescriptors = [NSSortDescriptor(keyPath: \CDCharacter.id, ascending: true)]
                
                let cdCharacters = try request.execute()
                return cdCharacters.map { $0.toDomain() }
            }
        }
    }
    
    public func toggleFavorite(characterId: Int) async throws -> Bool {
        let backgroundContext = container.newBackgroundContext()
        backgroundContext.mergePolicy = NSMergePolicy.mergeByPropertyObjectTrump
        
        return try await backgroundContext.perform {
            let request = CDCharacter.fetchRequest()
            request.predicate = NSPredicate(format: "id == %d", characterId)
            request.fetchLimit = 1
            
            guard let cdCharacter = try request.execute().first else {
                throw NSError(
                    domain: "CoreDataStorage",
                    code: 404,
                    userInfo: [NSLocalizedDescriptionKey: "No se encontró el personaje localmente para marcar como favorito."]
                )
            }
            
            cdCharacter.isFavorite.toggle()
            
            if backgroundContext.hasChanges {
                try backgroundContext.save()
            }
            
            AppLogger.info("Estado favorito del personaje \(characterId) cambiado a: \(cdCharacter.isFavorite)", category: .database)
            return cdCharacter.isFavorite
        }
    }
    
    public func getFavorites() async throws -> [Character] {
        let backgroundContext = container.newBackgroundContext()
        return try await backgroundContext.perform {
            let request = CDCharacter.fetchRequest()
            request.predicate = NSPredicate(format: "isFavorite == YES")
            request.sortDescriptors = [NSSortDescriptor(keyPath: \CDCharacter.id, ascending: true)]
            
            let cdCharacters = try request.execute()
            return cdCharacters.map { $0.toDomain() }
        }
    }
    
    public func fetchEpisodeDetails(episodeUrls: [String]) async throws -> [Episode] {
        var episodes: [Episode] = []
        var urlsToFetch: [String] = []
        
        // 1. Buscamos primero en el caché de memoria de forma segura (secuencial)
        for url in episodeUrls {
            if let cached = getCachedEpisode(for: url) {
                // Actualizamos el estado "visto" en caliente por si cambió en CoreData
                var updatedEpisode = cached
                updatedEpisode.isWatched = try await self.isEpisodeWatched(episodeUrl: url)
                episodes.append(updatedEpisode)
            } else {
                urlsToFetch.append(url)
            }
        }
        
        // Si todos los episodios ya estaban en caché, los devolvemos ordenados directamente
        if urlsToFetch.isEmpty {
            return episodes.sorted(by: { $0.id < $1.id })
        }
        
        AppLogger.debug("Caché de episodios: se descargarán \(urlsToFetch.count) episodios nuevos de red", category: .network)
        
        // 2. Descargamos en lote (Batch Fetching) los episodios que falten
        let dtos = try await apiClient.fetchEpisodes(urls: urlsToFetch)
        
        var newEpisodes: [Episode] = []
        for dto in dtos {
            let isWatched = try await self.isEpisodeWatched(episodeUrl: dto.url)
            newEpisodes.append(dto.toDomain(isWatched: isWatched))
        }
        
        // 3. Guardamos los nuevos episodios en el caché de memoria (secuencial y seguro)
        for episode in newEpisodes {
            setCachedEpisode(episode, for: episode.url)
            episodes.append(episode)
        }
        
        return episodes.sorted(by: { $0.id < $1.id })
    }
    
    public func markEpisodeWatched(episodeUrl: String, isWatched: Bool) async throws {
        let backgroundContext = container.newBackgroundContext()
        backgroundContext.mergePolicy = NSMergePolicy.mergeByPropertyObjectTrump
        
        try await backgroundContext.perform {
            let request = CDWatchedEpisode.fetchRequest()
            request.predicate = NSPredicate(format: "episodeUrl == %@", episodeUrl)
            request.fetchLimit = 1
            
            let existing = try request.execute().first
            
            if isWatched {
                if existing == nil {
                    let newWatched = CDWatchedEpisode(context: backgroundContext)
                    newWatched.episodeUrl = episodeUrl
                    newWatched.watchedAt = Date()
                    AppLogger.info("Episodio marcado como visto: \(episodeUrl)", category: .database)
                }
            } else {
                if let existing = existing {
                    backgroundContext.delete(existing)
                    AppLogger.info("Episodio desmarcado como visto: \(episodeUrl)", category: .database)
                }
            }
            
            if backgroundContext.hasChanges {
                try backgroundContext.save()
            }
        }
    }
    
    // MARK: - Helpers Privados
    
    /// Consulta de forma rápida si un episodio específico ya está marcado como visto
    private func isEpisodeWatched(episodeUrl: String) async throws -> Bool {
        let backgroundContext = container.newBackgroundContext()
        return try await backgroundContext.perform {
            let request = CDWatchedEpisode.fetchRequest()
            request.predicate = NSPredicate(format: "episodeUrl == %@", episodeUrl)
            request.fetchLimit = 1
            
            let count = try backgroundContext.count(for: request)
            return count > 0
        }
    }
}
