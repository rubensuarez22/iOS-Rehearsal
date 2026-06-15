//
//  CharacterDetailViewModelTests.swift
//  iOS-RehearsalTests
//
//  Created by Rubén Suárez on 14/06/26.
//

import Testing
import Foundation
@testable import iOS_Rehearsal

@Suite @MainActor struct CharacterDetailViewModelTests {
    
    private func makeMockCharacter() -> Character {
        return Character(
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
            episodeUrls: [
                "https://rickandmortyapi.com/api/episode/1",
                "https://rickandmortyapi.com/api/episode/2"
            ],
            isFavorite: false
        )
    }
    
    private func makeMockEpisodes() -> [Episode] {
        return [
            Episode(
                id: 1,
                name: "Pilot",
                airDate: "December 2, 2013",
                episode: "S01E01",
                characters: [],
                url: "https://rickandmortyapi.com/api/episode/1",
                created: "",
                isWatched: false
            ),
            Episode(
                id: 2,
                name: "Lawnmower Dog",
                airDate: "December 9, 2013",
                episode: "S01E02",
                characters: [],
                url: "https://rickandmortyapi.com/api/episode/2",
                created: "",
                isWatched: false
            )
        ]
    }
    
    @Test func testToggleFavorite() async throws {
        let mockRepo = MockCharacterRepository()
        mockRepo.mockCharacters = [makeMockCharacter()]
        
        let toggleFavoriteUseCase = ToggleFavoriteUseCase(repository: mockRepo)
        let getEpisodeDetailsUseCase = GetEpisodeDetailsUseCase(repository: mockRepo)
        let markEpisodeWatchedUseCase = MarkEpisodeWatchedUseCase(repository: mockRepo)
        
        let character = makeMockCharacter()
        let viewModel = CharacterDetailViewModel(
            character: character,
            toggleFavoriteUseCase: toggleFavoriteUseCase,
            getEpisodeDetailsUseCase: getEpisodeDetailsUseCase,
            markEpisodeWatchedUseCase: markEpisodeWatchedUseCase
        )
        
        // El estado favorito inicial del personaje es false
        let initialFav = viewModel.isFavorite
        #expect(initialFav == false)
        
        // Alternamos el estado
        await viewModel.toggleFavorite()
        
        let updatedFav = viewModel.isFavorite
        #expect(updatedFav == true)
        #expect(mockRepo.toggleFavoriteCalledCount == 1)
        #expect(mockRepo.toggleFavoriteLastId == 1)
    }
    
    @Test func testLoadEpisodesSuccess() async throws {
        let mockRepo = MockCharacterRepository()
        mockRepo.mockEpisodes = makeMockEpisodes()
        
        let toggleFavoriteUseCase = ToggleFavoriteUseCase(repository: mockRepo)
        let getEpisodeDetailsUseCase = GetEpisodeDetailsUseCase(repository: mockRepo)
        let markEpisodeWatchedUseCase = MarkEpisodeWatchedUseCase(repository: mockRepo)
        
        let character = makeMockCharacter()
        let viewModel = CharacterDetailViewModel(
            character: character,
            toggleFavoriteUseCase: toggleFavoriteUseCase,
            getEpisodeDetailsUseCase: getEpisodeDetailsUseCase,
            markEpisodeWatchedUseCase: markEpisodeWatchedUseCase
        )
        
        await viewModel.loadEpisodes()
        
        let state = viewModel.episodesState
        switch state {
        case .success(let episodes):
            #expect(episodes.count == 2)
            #expect(episodes[0].name == "Pilot")
            #expect(episodes[1].name == "Lawnmower Dog")
        default:
            Issue.record("El estado de episodios debería ser success")
        }
        
        #expect(mockRepo.fetchEpisodeDetailsCalledCount == 1)
    }
    
    @Test func testToggleEpisodeWatched() async throws {
        let mockRepo = MockCharacterRepository()
        let mockEpisodesList = makeMockEpisodes()
        mockRepo.mockEpisodes = mockEpisodesList
        
        let toggleFavoriteUseCase = ToggleFavoriteUseCase(repository: mockRepo)
        let getEpisodeDetailsUseCase = GetEpisodeDetailsUseCase(repository: mockRepo)
        let markEpisodeWatchedUseCase = MarkEpisodeWatchedUseCase(repository: mockRepo)
        
        let character = makeMockCharacter()
        let viewModel = CharacterDetailViewModel(
            character: character,
            toggleFavoriteUseCase: toggleFavoriteUseCase,
            getEpisodeDetailsUseCase: getEpisodeDetailsUseCase,
            markEpisodeWatchedUseCase: markEpisodeWatchedUseCase
        )
        
        // Cargamos primero los episodios
        await viewModel.loadEpisodes()
        
        // Comprobamos que el episodio 1 no está visto inicialmente
        let stateBefore = viewModel.episodesState
        if case .success(let episodes) = stateBefore {
            #expect(episodes[0].isWatched == false)
            
            // Cambiamos el estado
            await viewModel.toggleEpisodeWatched(episode: episodes[0])
        } else {
            Issue.record("Los episodios no se cargaron correctamente")
        }
        
        // Verificamos el cambio del estado a visto
        let stateAfter = viewModel.episodesState
        if case .success(let episodes) = stateAfter {
            #expect(episodes[0].isWatched == true)
            #expect(mockRepo.markEpisodeWatchedCalledCount == 1)
            #expect(mockRepo.markEpisodeWatchedLastParameters?.episodeUrl == "https://rickandmortyapi.com/api/episode/1")
            #expect(mockRepo.markEpisodeWatchedLastParameters?.isWatched == true)
        } else {
            Issue.record("El estado después de cambiar visto debería seguir siendo success")
        }
    }
}
