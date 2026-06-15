//
//  DependencyRegistry.swift
//  iOS-Rehearsal
//
//  Created by Rubén Suárez on 14/06/26.
//

import Foundation
import CoreData
import Swinject

// MARK: - Dependency Registry
public final class DependencyRegistry {
    /// Instancia única para el registro global de la aplicación (Patrón Singleton)
    public static let shared = DependencyRegistry()
    
    /// El contenedor centralizado de Swinject
    public let container = Container()
    
    private init() {
        registerDependencies()
    }
    
    private func registerDependencies() {
        // MARK: - 1. Base de datos & Red (Infraestructura)
        
        // Registramos el contenedor persistente de CoreData
        container.register(NSPersistentContainer.self) { _ in
            PersistenceController.shared.container
        }.inObjectScope(.container) // Mantiene una única instancia compartida (Singleton en Swinject)
        
        // Registramos el cliente de API
        container.register(APIClientProtocol.self) { _ in
            APIClient()
        }.inObjectScope(.container)
        
        // Registramos el autenticador biométrico
        container.register(BiometricAuthenticatorProtocol.self) { _ in
            #if DEBUG
            if ProcessInfo.processInfo.arguments.contains("--uitesting") {
                return FakeBiometricAuthenticator()
            }
            #endif
            return BiometricAuthenticator()
        }.inObjectScope(.container)
        
        // MARK: - 2. Repositorios
        
        container.register(CharacterRepositoryProtocol.self) { resolver in
            guard let apiClient = resolver.resolve(APIClientProtocol.self) else {
                fatalError("[DI] No se pudo resolver APIClientProtocol. Verifica el registro en DependencyRegistry.")
            }
            guard let dbContainer = resolver.resolve(NSPersistentContainer.self) else {
                fatalError("[DI] No se pudo resolver NSPersistentContainer. Verifica el registro en DependencyRegistry.")
            }
            return CharacterRepository(apiClient: apiClient, container: dbContainer)
        }.inObjectScope(.container)
        
        // MARK: - 3. Casos de Uso
        
        container.register(GetCharactersUseCase.self) { resolver in
            guard let repo = resolver.resolve(CharacterRepositoryProtocol.self) else {
                fatalError("[DI] No se pudo resolver CharacterRepositoryProtocol. Verifica el registro en DependencyRegistry.")
            }
            return GetCharactersUseCase(repository: repo)
        }
        
        container.register(ToggleFavoriteUseCase.self) { resolver in
            guard let repo = resolver.resolve(CharacterRepositoryProtocol.self) else {
                fatalError("[DI] No se pudo resolver CharacterRepositoryProtocol. Verifica el registro en DependencyRegistry.")
            }
            return ToggleFavoriteUseCase(repository: repo)
        }
        
        container.register(GetFavoritesUseCase.self) { resolver in
            guard let repo = resolver.resolve(CharacterRepositoryProtocol.self) else {
                fatalError("[DI] No se pudo resolver CharacterRepositoryProtocol. Verifica el registro en DependencyRegistry.")
            }
            return GetFavoritesUseCase(repository: repo)
        }
        
        container.register(GetEpisodeDetailsUseCase.self) { resolver in
            guard let repo = resolver.resolve(CharacterRepositoryProtocol.self) else {
                fatalError("[DI] No se pudo resolver CharacterRepositoryProtocol. Verifica el registro en DependencyRegistry.")
            }
            return GetEpisodeDetailsUseCase(repository: repo)
        }
        
        container.register(MarkEpisodeWatchedUseCase.self) { resolver in
            guard let repo = resolver.resolve(CharacterRepositoryProtocol.self) else {
                fatalError("[DI] No se pudo resolver CharacterRepositoryProtocol. Verifica el registro en DependencyRegistry.")
            }
            return MarkEpisodeWatchedUseCase(repository: repo)
        }
        
        container.register(AuthenticateBiometricsUseCase.self) { resolver in
            guard let auth = resolver.resolve(BiometricAuthenticatorProtocol.self) else {
                fatalError("[DI] No se pudo resolver BiometricAuthenticatorProtocol. Verifica el registro en DependencyRegistry.")
            }
            return AuthenticateBiometricsUseCase(authenticator: auth)
        }
        
        // MARK: - 4. View Models
        
        container.register(CharacterListViewModel.self) { resolver in
            guard let useCase = resolver.resolve(GetCharactersUseCase.self) else {
                fatalError("[DI] No se pudo resolver GetCharactersUseCase. Verifica el registro en DependencyRegistry.")
            }
            return CharacterListViewModel(getCharactersUseCase: useCase)
        }
        
        container.register(CharacterDetailViewModel.self) { (resolver, character: Character) in
            guard let toggleFavorite = resolver.resolve(ToggleFavoriteUseCase.self) else {
                fatalError("[DI] No se pudo resolver ToggleFavoriteUseCase. Verifica el registro en DependencyRegistry.")
            }
            guard let getEpisodeDetails = resolver.resolve(GetEpisodeDetailsUseCase.self) else {
                fatalError("[DI] No se pudo resolver GetEpisodeDetailsUseCase. Verifica el registro en DependencyRegistry.")
            }
            guard let markEpisodeWatched = resolver.resolve(MarkEpisodeWatchedUseCase.self) else {
                fatalError("[DI] No se pudo resolver MarkEpisodeWatchedUseCase. Verifica el registro en DependencyRegistry.")
            }
            
            return CharacterDetailViewModel(
                character: character,
                toggleFavoriteUseCase: toggleFavorite,
                getEpisodeDetailsUseCase: getEpisodeDetails,
                markEpisodeWatchedUseCase: markEpisodeWatched
            )
        }
        
        container.register(FavoritesViewModel.self) { resolver in
            guard let auth = resolver.resolve(AuthenticateBiometricsUseCase.self) else {
                fatalError("[DI] No se pudo resolver AuthenticateBiometricsUseCase. Verifica el registro en DependencyRegistry.")
            }
            guard let getFavs = resolver.resolve(GetFavoritesUseCase.self) else {
                fatalError("[DI] No se pudo resolver GetFavoritesUseCase. Verifica el registro en DependencyRegistry.")
            }
            
            return FavoritesViewModel(
                authenticateBiometricsUseCase: auth,
                getFavoritesUseCase: getFavs
            )
        }
    }
}

#if DEBUG
/// Un autenticador biométrico falso para pruebas de UI que simula éxito inmediato
public final class FakeBiometricAuthenticator: BiometricAuthenticatorProtocol {
    public init() {}
    public func canEvaluatePolicy() -> Bool {
        return true
    }
    public func authenticate() async throws -> Bool {
        // Simula un breve retardo de procesamiento de 0.1 segundos
        try? await Task.sleep(nanoseconds: 100_000_000)
        return true
    }
}
#endif
