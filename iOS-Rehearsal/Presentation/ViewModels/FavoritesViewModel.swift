//
//  FavoritesViewModel.swift
//  iOS-Rehearsal
//
//  Created by Rubén Suárez on 14/06/26.
//

import Foundation
import Combine

// MARK: - View State
public enum FavoritesViewState: Equatable {
    case idle
    case loading
    case success([Character])
    case error(String)
}

// MARK: - View Model
@MainActor
public final class FavoritesViewModel: ObservableObject {
    // MARK: - Properties
    
    private let authenticateBiometricsUseCase: AuthenticateBiometricsUseCase
    private let getFavoritesUseCase: GetFavoritesUseCase
    
    @Published public var isAuthenticated: Bool = false
    @Published public var viewState: FavoritesViewState = .idle
    @Published public var authError: String? = nil
    
    // MARK: - Init
    
    public init(
        authenticateBiometricsUseCase: AuthenticateBiometricsUseCase,
        getFavoritesUseCase: GetFavoritesUseCase
    ) {
        self.authenticateBiometricsUseCase = authenticateBiometricsUseCase
        self.getFavoritesUseCase = getFavoritesUseCase
    }
    
    // MARK: - Operations
    
    /// Lanza la autenticación biométrica y, si es exitosa, carga los favoritos
    public func authenticateAndLoad() async {
        authError = nil
        
        do {
            // 1. Solicitamos autenticación por Face ID / Touch ID
            let success = try await authenticateBiometricsUseCase.execute()
            
            if success {
                self.isAuthenticated = true
                // 2. Si es exitosa, cargamos los favoritos de CoreData
                await loadFavorites()
            } else {
                self.isAuthenticated = false
                self.authError = "La autenticación biométrica falló."
            }
        } catch {
            AppLogger.error("Error al autenticar biométricamente en Favoritos", category: .presentation, error: error)
            self.isAuthenticated = false
            self.authError = error.localizedDescription
        }
    }
    
    /// Carga la lista de personajes favoritos
    public func loadFavorites() async {
        guard isAuthenticated else { return }
        
        viewState = .loading
        
        do {
            let favorites = try await getFavoritesUseCase.execute()
            
            if favorites.isEmpty {
                viewState = .success([])
            } else {
                viewState = .success(favorites)
            }
        } catch {
            AppLogger.error("Error al cargar favoritos desde CoreData", category: .presentation, error: error)
            viewState = .error(error.localizedDescription)
        }
    }
    
    /// Cierra la sesión y vuelve a bloquear la pantalla
    public func lock() {
        self.isAuthenticated = false
        self.viewState = .idle
        self.authError = nil
    }
}
