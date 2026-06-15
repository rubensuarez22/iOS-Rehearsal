//
//  ModelMappers.swift
//  iOS-Rehearsal
//
//  Created by Rubén Suárez on 14/06/26.
//

import Foundation
import CoreData

// MARK: - CharacterDTO to Domain Character
extension CharacterDTO {
    /// Convierte un DTO de red a un modelo de Dominio puro, calculando coordenadas simuladas estables.
    /// Es nonisolated porque es una función de mapeo pura y segura para ejecutar en hilos de fondo.
    nonisolated public func toDomain(isFavorite: Bool = false) -> Character {
        // Generamos coordenadas simuladas estables distribuidas en espiral alrededor del CERN (Suiza)
        let angle = Double(id) * 0.5
        let radius = 0.01 + (Double(id).truncatingRemainder(dividingBy: 10) * 0.005)
        let lat = 46.2044 + (sin(angle) * radius)
        let lon = 6.1432 + (cos(angle) * radius)
        
        let domainStatus = CharacterStatus(rawValue: status) ?? .unknown
        
        return Character(
            id: id,
            name: name,
            status: domainStatus,
            species: species,
            type: type,
            gender: gender,
            image: image,
            url: url,
            originName: origin.name,
            locationName: location.name,
            locationUrl: location.url,
            episodeUrls: episode,
            isFavorite: isFavorite,
            latitude: lat,
            longitude: lon
        )
    }
}

// MARK: - CDCharacter to Domain Character
extension CDCharacter {
    /// Convierte una entidad de CoreData a un modelo de Dominio puro.
    /// NO es nonisolated porque CoreData requiere confinamiento de hilo y accede a propiedades administradas.
    public func toDomain() -> Character {
        let domainStatus = CharacterStatus(rawValue: status ?? "") ?? .unknown
        
        // Decodificamos el array de URLs de episodios del binario guardado en la base de datos
        var episodes: [String] = []
        if let data = episodeUrlsData {
            episodes = (try? JSONDecoder().decode([String].self, from: data)) ?? []
        }
        
        return Character(
            id: Int(id),
            name: name ?? "",
            status: domainStatus,
            species: species ?? "",
            type: type ?? "",
            gender: gender ?? "",
            image: image ?? "",
            url: url ?? "",
            originName: originName ?? "",
            locationName: locationName ?? "",
            locationUrl: locationUrl ?? "",
            episodeUrls: episodes,
            isFavorite: isFavorite,
            latitude: latitude,
            longitude: longitude
        )
    }
}

// MARK: - EpisodeDTO to Domain Episode
extension EpisodeDTO {
    /// Convierte un DTO de red de episodio a un modelo de Dominio puro.
    /// Es nonisolated porque es una función de mapeo pura y segura para ejecutar en hilos de fondo.
    nonisolated public func toDomain(isWatched: Bool = false) -> Episode {
        return Episode(
            id: id,
            name: name,
            airDate: air_date,
            episode: episode,
            characters: characters,
            url: url,
            created: created,
            isWatched: isWatched
        )
    }
}
