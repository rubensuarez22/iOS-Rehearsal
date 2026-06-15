//
//  FavoritesViewModelTests.swift
//  iOS-RehearsalTests
//
//  Created by Rubén Suárez on 14/06/26.
//

import Testing
import Foundation
@testable import iOS_Rehearsal

@Suite @MainActor struct FavoritesViewModelTests {
    
    private func makeMockCharacters() -> [Character] {
        return [
            Character(
                id: 1,
                name: "Rick Sanchez",
                status: .alive,
                species: "Human",
                type: "",
                gender: "Male",
                image: "https://rickandmortyapi.com/api/character/avatar/1.jpeg",
                url: "https://rickandmortyapi.com/api/character/1",
                originName: "Earth (C-137)",
                locationName: "Citadel of Ricks",
                locationUrl: "https://rickandmortyapi.com/api/location/3",
                episodeUrls: [],
                isFavorite: true
            )
        ]
    }
    
    @Test func testInitialStateIsLocked() async throws {
        let mockRepo = MockCharacterRepository()
        let mockAuth = MockBiometricAuthenticator()
        
        let authenticateBiometricsUseCase = AuthenticateBiometricsUseCase(authenticator: mockAuth)
        let getFavoritesUseCase = GetFavoritesUseCase(repository: mockRepo)
        
        let viewModel = FavoritesViewModel(
            authenticateBiometricsUseCase: authenticateBiometricsUseCase,
            getFavoritesUseCase: getFavoritesUseCase
        )
        
        #expect(viewModel.isAuthenticated == false)
        #expect(viewModel.viewState == .idle)
        #expect(viewModel.authError == nil)
    }
    
    @Test func testAuthenticationSuccessLoadsFavorites() async throws {
        let mockRepo = MockCharacterRepository()
        mockRepo.mockCharacters = makeMockCharacters()
        mockRepo.favoriteStates[1] = true
        
        let mockAuth = MockBiometricAuthenticator()
        mockAuth.shouldCanEvaluatePolicy = true
        mockAuth.shouldAuthenticateSuccessfully = true
        
        let authenticateBiometricsUseCase = AuthenticateBiometricsUseCase(authenticator: mockAuth)
        let getFavoritesUseCase = GetFavoritesUseCase(repository: mockRepo)
        
        let viewModel = FavoritesViewModel(
            authenticateBiometricsUseCase: authenticateBiometricsUseCase,
            getFavoritesUseCase: getFavoritesUseCase
        )
        
        // Ejecutamos autenticación
        await viewModel.authenticateAndLoad()
        
        #expect(viewModel.isAuthenticated == true)
        #expect(mockAuth.canEvaluatePolicyCalledCount == 1)
        #expect(mockAuth.authenticateCalledCount == 1)
        
        let state = viewModel.viewState
        switch state {
        case .success(let favorites):
            #expect(favorites.count == 1)
            #expect(favorites[0].name == "Rick Sanchez")
        default:
            Issue.record("El estado de favoritos debería ser success")
        }
        
        #expect(mockRepo.getFavoritesCalledCount == 1)
    }
    
    @Test func testAuthenticationFailure() async throws {
        let mockRepo = MockCharacterRepository()
        let mockAuth = MockBiometricAuthenticator()
        mockAuth.shouldCanEvaluatePolicy = true
        mockAuth.shouldAuthenticateSuccessfully = false // El usuario cancela o falla
        
        let authenticateBiometricsUseCase = AuthenticateBiometricsUseCase(authenticator: mockAuth)
        let getFavoritesUseCase = GetFavoritesUseCase(repository: mockRepo)
        
        let viewModel = FavoritesViewModel(
            authenticateBiometricsUseCase: authenticateBiometricsUseCase,
            getFavoritesUseCase: getFavoritesUseCase
        )
        
        await viewModel.authenticateAndLoad()
        
        #expect(viewModel.isAuthenticated == false)
        #expect(viewModel.authError == "La autenticación biométrica falló.")
        #expect(viewModel.viewState == .idle)
        
        #expect(mockRepo.getFavoritesCalledCount == 0) // No debe cargar favoritos si no está autenticado
    }
    
    @Test func testLockSession() async throws {
        let mockRepo = MockCharacterRepository()
        let mockAuth = MockBiometricAuthenticator()
        mockAuth.shouldCanEvaluatePolicy = true
        mockAuth.shouldAuthenticateSuccessfully = true
        
        let authenticateBiometricsUseCase = AuthenticateBiometricsUseCase(authenticator: mockAuth)
        let getFavoritesUseCase = GetFavoritesUseCase(repository: mockRepo)
        
        let viewModel = FavoritesViewModel(
            authenticateBiometricsUseCase: authenticateBiometricsUseCase,
            getFavoritesUseCase: getFavoritesUseCase
        )
        
        // Autenticamos primero
        await viewModel.authenticateAndLoad()
        #expect(viewModel.isAuthenticated == true)
        
        // Bloqueamos
        viewModel.lock()
        
        #expect(viewModel.isAuthenticated == false)
        #expect(viewModel.viewState == .idle)
        #expect(viewModel.authError == nil)
    }
}
