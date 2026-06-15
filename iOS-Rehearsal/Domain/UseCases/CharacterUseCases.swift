//
//  CharacterUseCases.swift
//  iOS-Rehearsal
//
//  Created by Rubén Suárez on 14/06/26.
//

import Foundation

// MARK: - Biometric Authenticator Protocol
public protocol BiometricAuthenticatorProtocol {
    /// Determina si el dispositivo cuenta con hardware biométrico disponible y configurado (Face ID / Touch ID).
    func canEvaluatePolicy() -> Bool
    
    /// Lanza la alerta nativa del sistema para solicitar la autenticación del usuario.
    func authenticate() async throws -> Bool
}

// MARK: - Get Characters Use Case
public final class GetCharactersUseCase {
    private let repository: CharacterRepositoryProtocol
    
    public init(repository: CharacterRepositoryProtocol) {
        self.repository = repository
    }
    
    public func execute(page: Int, name: String?, status: String?, species: String?) async throws -> [Character] {
        return try await repository.fetchCharacters(page: page, name: name, status: status, species: species)
    }
}

// MARK: - Toggle Favorite Use Case
public final class ToggleFavoriteUseCase {
    private let repository: CharacterRepositoryProtocol
    
    public init(repository: CharacterRepositoryProtocol) {
        self.repository = repository
    }
    
    public func execute(characterId: Int) async throws -> Bool {
        return try await repository.toggleFavorite(characterId: characterId)
    }
}

// MARK: - Get Favorites Use Case
public final class GetFavoritesUseCase {
    private let repository: CharacterRepositoryProtocol
    
    public init(repository: CharacterRepositoryProtocol) {
        self.repository = repository
    }
    
    public func execute() async throws -> [Character] {
        return try await repository.getFavorites()
    }
}

// MARK: - Get Episode Details Use Case
public final class GetEpisodeDetailsUseCase {
    private let repository: CharacterRepositoryProtocol
    
    public init(repository: CharacterRepositoryProtocol) {
        self.repository = repository
    }
    
    public func execute(episodeUrls: [String]) async throws -> [Episode] {
        return try await repository.fetchEpisodeDetails(episodeUrls: episodeUrls)
    }
}

// MARK: - Mark Episode Watched Use Case
public final class MarkEpisodeWatchedUseCase {
    private let repository: CharacterRepositoryProtocol
    
    public init(repository: CharacterRepositoryProtocol) {
        self.repository = repository
    }
    
    public func execute(episodeUrl: String, isWatched: Bool) async throws {
        try await repository.markEpisodeWatched(episodeUrl: episodeUrl, isWatched: isWatched)
    }
}

// MARK: - Biometric Error Definition
public enum BiometricError: LocalizedError {
    case notAvailable
    
    public var errorDescription: String? {
        switch self {
        case .notAvailable:
            return "Autenticación biométrica no disponible en este dispositivo."
        }
    }
}

// MARK: - Authenticate Biometrics Use Case
public final class AuthenticateBiometricsUseCase {
    private let authenticator: BiometricAuthenticatorProtocol
    
    public init(authenticator: BiometricAuthenticatorProtocol) {
        self.authenticator = authenticator
    }
    
    public func execute() async throws -> Bool {
        guard authenticator.canEvaluatePolicy() else {
            throw BiometricError.notAvailable
        }
        return try await authenticator.authenticate()
    }
}
