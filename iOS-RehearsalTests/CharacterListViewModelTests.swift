//
//  CharacterListViewModelTests.swift
//  iOS-RehearsalTests
//
//  Created by Rubén Suárez on 14/06/26.
//

import Testing
import Foundation
import Combine
@testable import iOS_Rehearsal

@Suite @MainActor struct CharacterListViewModelTests {
    
    // Helper para generar datos de prueba simples
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
                episodeUrls: ["https://rickandmortyapi.com/api/episode/1"]
            ),
            Character(
                id: 2,
                name: "Morty Smith",
                status: .alive,
                species: "Human",
                type: "",
                gender: "Male",
                image: "https://rickandmortyapi.com/api/character/avatar/2.jpeg",
                url: "https://rickandmortyapi.com/api/character/2",
                originName: "unknown",
                locationName: "Citadel of Ricks",
                locationUrl: "https://rickandmortyapi.com/api/location/3",
                episodeUrls: ["https://rickandmortyapi.com/api/episode/1"]
            ),
            Character(
                id: 3,
                name: "Summer Smith",
                status: .alive,
                species: "Human",
                type: "",
                gender: "Female",
                image: "https://rickandmortyapi.com/api/character/avatar/3.jpeg",
                url: "https://rickandmortyapi.com/api/character/3",
                originName: "Earth (Replacement Dimension)",
                locationName: "Earth (Replacement Dimension)",
                locationUrl: "https://rickandmortyapi.com/api/location/20",
                episodeUrls: ["https://rickandmortyapi.com/api/episode/6"]
            )
        ]
    }
    
    // Helper para generar una lista arbitraria de personajes simulando el tamaño real de la API
    private func makeManyMockCharacters(count: Int) -> [Character] {
        return (1...count).map { id in
            Character(
                id: id,
                name: "Character \(id)",
                status: .alive,
                species: "Human",
                type: "",
                gender: "Male",
                image: "https://rickandmortyapi.com/api/character/avatar/\(id).jpeg",
                url: "https://rickandmortyapi.com/api/character/\(id)",
                originName: "Earth",
                locationName: "Earth",
                locationUrl: "https://rickandmortyapi.com/api/location/1",
                episodeUrls: ["https://rickandmortyapi.com/api/episode/1"]
            )
        }
    }
    
    @Test func testInitialStateIsIdle() async throws {
        let mockRepo = MockCharacterRepository()
        let getCharactersUseCase = GetCharactersUseCase(repository: mockRepo)
        let viewModel = CharacterListViewModel(getCharactersUseCase: getCharactersUseCase)
        
        let state = viewModel.viewState
        #expect(state == .idle)
    }
    
    @Test func testFetchCharactersSuccess() async throws {
        let mockRepo = MockCharacterRepository()
        mockRepo.pageSize = 2 // Forzamos tamaño de página de 2 para probar la paginación pequeña
        mockRepo.mockCharacters = makeMockCharacters()
        
        let getCharactersUseCase = GetCharactersUseCase(repository: mockRepo)
        let viewModel = CharacterListViewModel(getCharactersUseCase: getCharactersUseCase)
        
        // Ejecutamos la carga inicial
        await viewModel.resetAndFetch()
        
        let state = viewModel.viewState
        switch state {
        case .success(let characters):
            #expect(characters.count == 2) // Paginación simulada de 2 en 2
            #expect(characters[0].name == "Rick Sanchez")
            #expect(characters[1].name == "Morty Smith")
        default:
            Issue.record("El estado debería ser success")
        }
        
        let callCount = mockRepo.fetchCharactersCalledCount
        #expect(callCount == 1)
    }
    
    @Test func testFetchCharactersEmpty() async throws {
        let mockRepo = MockCharacterRepository()
        mockRepo.mockCharacters = []
        
        let getCharactersUseCase = GetCharactersUseCase(repository: mockRepo)
        let viewModel = CharacterListViewModel(getCharactersUseCase: getCharactersUseCase)
        
        await viewModel.resetAndFetch()
        
        let state = viewModel.viewState
        #expect(state == .empty)
    }
    
    @Test func testFetchCharactersError() async throws {
        let mockRepo = MockCharacterRepository()
        mockRepo.shouldThrowError = true
        mockRepo.errorToThrow = NSError(domain: "Network", code: -1009, userInfo: [NSLocalizedDescriptionKey: "Sin conexión a internet"])
        
        let getCharactersUseCase = GetCharactersUseCase(repository: mockRepo)
        let viewModel = CharacterListViewModel(getCharactersUseCase: getCharactersUseCase)
        
        await viewModel.resetAndFetch()
        
        let state = viewModel.viewState
        switch state {
        case .error(let message):
            #expect(message == "Sin conexión a internet")
        default:
            Issue.record("El estado debería ser error")
        }
    }
    
    @Test func testPaginationLoadMore() async throws {
        let mockRepo = MockCharacterRepository()
        mockRepo.pageSize = 20 // Tamaño estándar de la API de producción
        mockRepo.mockCharacters = makeManyMockCharacters(count: 21) // 21 personajes para requerir una segunda página
        
        let getCharactersUseCase = GetCharactersUseCase(repository: mockRepo)
        let viewModel = CharacterListViewModel(getCharactersUseCase: getCharactersUseCase)
        
        // Página 1 (debe traer 20 personajes)
        await viewModel.resetAndFetch()
        
        let state1 = viewModel.viewState
        if case .success(let characters) = state1 {
            #expect(characters.count == 20)
        } else {
            Issue.record("La página 1 debería cargar con éxito")
        }
        
        // Página 2 (debe traer el 21º personaje)
        await viewModel.loadNextPage()
        
        let state2 = viewModel.viewState
        switch state2 {
        case .success(let characters):
            #expect(characters.count == 21)
            #expect(characters[20].name == "Character 21")
        default:
            Issue.record("El estado debería ser success con 21 personajes")
        }
        
        #expect(mockRepo.fetchCharactersCalledCount == 2)
    }
}
