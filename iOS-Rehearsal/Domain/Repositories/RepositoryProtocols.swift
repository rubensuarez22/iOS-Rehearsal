//
//  RepositoryProtocols.swift
//  iOS-Rehearsal
//
//  Created by Rubén Suárez on 14/06/26.
//

import Foundation

// MARK: - Character Repository Protocol
public protocol CharacterRepositoryProtocol {
    /// Obtiene el listado de personajes paginado, con filtros opcionales de búsqueda.
    /// Si ocurre un error de red, debe retornar los datos almacenados localmente en CoreData.
    func fetchCharacters(
        page: Int,
        name: String?,
        status: String?,
        species: String?
    ) async throws -> [Character]
    
    /// Alterna el estado favorito de un personaje en la base de datos local y retorna el nuevo estado.
    func toggleFavorite(characterId: Int) async throws -> Bool
    
    /// Obtiene únicamente los personajes marcados como favoritos desde la base de datos local.
    func getFavorites() async throws -> [Character]
    
    /// Obtiene los detalles completos (nombre y número) de una lista de episodios a partir de sus URLs.
    func fetchEpisodeDetails(episodeUrls: [String]) async throws -> [Episode]
    
    /// Guarda en la base de datos si un episodio específico ha sido marcado como visto o no.
    func markEpisodeWatched(episodeUrl: String, isWatched: Bool) async throws
}
