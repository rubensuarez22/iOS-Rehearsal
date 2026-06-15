//
//  APIClient.swift
//  iOS-Rehearsal
//
//  Created by Rubén Suárez on 14/06/26.
//

import Foundation

// MARK: - API Error Definition
public enum APIError: LocalizedError {
    case serverError(statusCode: Int)
    case rateLimited
    case decodingFailed(underlyingError: Error)
    
    public var errorDescription: String? {
        switch self {
        case .serverError(let code): return "Error del servidor (HTTP \(code))"
        case .rateLimited: return "Demasiadas peticiones al servidor (Rate Limiting). Intenta de nuevo más tarde."
        case .decodingFailed(let error): return "Error al procesar datos: \(error.localizedDescription)"
        }
    }
}

// MARK: - API Client Protocol
public protocol APIClientProtocol {
    /// Descarga los personajes paginados y filtrados
    func fetchCharacters(
        page: Int,
        name: String?,
        status: String?,
        species: String?
    ) async throws -> CharacterResponseDTO
    
    /// Descarga una lista de episodios en una única petición por lote (Batch Fetching)
    func fetchEpisodes(urls: [String]) async throws -> [EpisodeDTO]
}

// MARK: - API Client Implementation
public final class APIClient: APIClientProtocol {
    private let session: URLSession
    
    public init(session: URLSession = .shared) {
        self.session = session
    }
    
    public func fetchCharacters(
        page: Int,
        name: String?,
        status: String?,
        species: String?
    ) async throws -> CharacterResponseDTO {
        guard var components = URLComponents(string: "https://rickandmortyapi.com/api/character") else {
            throw URLError(.badURL)
        }
        var queryItems = [URLQueryItem(name: "page", value: String(page))]
        
        if let name = name, !name.isEmpty {
            queryItems.append(URLQueryItem(name: "name", value: name))
        }
        if let status = status, !status.isEmpty {
            queryItems.append(URLQueryItem(name: "status", value: status))
        }
        if let species = species, !species.isEmpty {
            queryItems.append(URLQueryItem(name: "species", value: species))
        }
        
        components.queryItems = queryItems
        
        guard let url = components.url else {
            throw URLError(.badURL)
        }
        
        AppLogger.debug("Iniciando petición GET: \(url.absoluteString)", category: .network)
        
        let (data, response) = try await session.data(from: url)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            AppLogger.error("Respuesta inválida (No es HTTP)", category: .network)
            throw URLError(.badServerResponse)
        }
        
        AppLogger.debug("Petición completada con código HTTP: \(httpResponse.statusCode)", category: .network)
        
        guard httpResponse.statusCode == 200 else {
            if httpResponse.statusCode == 404 {
                // La API de Rick & Morty devuelve 404 si la búsqueda no encuentra ningún personaje.
                // Lo tratamos como una lista vacía para mostrar el estado vacío amigable en la UI.
                return CharacterResponseDTO(
                    info: PageInfoDTO(count: 0, pages: 0, next: nil, prev: nil),
                    results: []
                )
            }
            if httpResponse.statusCode == 429 {
                throw APIError.rateLimited
            }
            throw APIError.serverError(statusCode: httpResponse.statusCode)
        }
        
        do {
            let decoder = JSONDecoder()
            let decoded = try decoder.decode(CharacterResponseDTO.self, from: data)
            return decoded
        } catch {
            AppLogger.error("Error al decodificar JSON de personajes", category: .network, error: error)
            throw APIError.decodingFailed(underlyingError: error)
        }
    }
    
    public func fetchEpisodes(urls: [String]) async throws -> [EpisodeDTO] {
        guard !urls.isEmpty else { return [] }
        
        // Extraemos los IDs numéricos de las URLs de los episodios
        let ids = urls.compactMap { url -> String? in
            guard let lastComponent = url.split(separator: "/").last else { return nil }
            return String(lastComponent)
        }
        
        guard !ids.isEmpty else { return [] }
        
        // Formamos la URL por lote. Si es 1 solo ID pides "/1", si son varios pides "/1,2,3"
        let urlString: String
        if ids.count == 1 {
            urlString = "https://rickandmortyapi.com/api/episode/\(ids[0])"
        } else {
            urlString = "https://rickandmortyapi.com/api/episode/\(ids.joined(separator: ","))"
        }
        
        guard let url = URL(string: urlString) else {
            throw URLError(.badURL)
        }
        
        AppLogger.debug("Iniciando petición GET por Lote de Episodios (\(ids.count) IDs): \(url.absoluteString)", category: .network)
        
        let (data, response) = try await session.data(from: url)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            AppLogger.error("Respuesta de episodios inválida (No es HTTP)", category: .network)
            throw URLError(.badServerResponse)
        }
        
        guard httpResponse.statusCode == 200 else {
            if httpResponse.statusCode == 429 {
                throw APIError.rateLimited
            }
            throw APIError.serverError(statusCode: httpResponse.statusCode)
        }
        
        do {
            let decoder = JSONDecoder()
            
            if ids.count == 1 {
                // Quirk de la API: 1 solo ID devuelve un objeto suelto
                let singleEpisode = try decoder.decode(EpisodeDTO.self, from: data)
                return [singleEpisode]
            } else {
                // Múltiples IDs devuelven un array de objetos
                let episodes = try decoder.decode([EpisodeDTO].self, from: data)
                return episodes
            }
        } catch {
            AppLogger.error("Error al decodificar JSON de episodios por lote", category: .network, error: error)
            throw APIError.decodingFailed(underlyingError: error)
        }
    }
}
