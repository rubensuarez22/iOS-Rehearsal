//
//  CharacterDetailViewModel.swift
//  iOS-Rehearsal
//
//  Created by Rubén Suárez on 14/06/26.
//

import Foundation
import Combine

// MARK: - View State
public enum EpisodesLoadState: Equatable {
    case loading
    case success([Episode])
    case error(String)
}

// MARK: - View Model
@MainActor
public final class CharacterDetailViewModel: ObservableObject {
    // MARK: - Properties
    
    private let toggleFavoriteUseCase: ToggleFavoriteUseCase
    private let getEpisodeDetailsUseCase: GetEpisodeDetailsUseCase
    private let markEpisodeWatchedUseCase: MarkEpisodeWatchedUseCase
    
    @Published public var character: Character
    @Published public var episodesState: EpisodesLoadState = .loading
    @Published public var isFavorite: Bool
    
    // MARK: - Init
    
    public init(
        character: Character,
        toggleFavoriteUseCase: ToggleFavoriteUseCase,
        getEpisodeDetailsUseCase: GetEpisodeDetailsUseCase,
        markEpisodeWatchedUseCase: MarkEpisodeWatchedUseCase
    ) {
        self.character = character
        self.toggleFavoriteUseCase = toggleFavoriteUseCase
        self.getEpisodeDetailsUseCase = getEpisodeDetailsUseCase
        self.markEpisodeWatchedUseCase = markEpisodeWatchedUseCase
        self.isFavorite = character.isFavorite
    }
    
    // MARK: - Operations
    
    /// Alterna el estado favorito del personaje
    public func toggleFavorite() async {
        do {
            let newFavoriteStatus = try await toggleFavoriteUseCase.execute(characterId: character.id)
            self.isFavorite = newFavoriteStatus
            self.character.isFavorite = newFavoriteStatus
        } catch {
            AppLogger.error("Error al alternar favorito en ViewModel de Detalle", category: .presentation, error: error)
        }
    }
    
    /// Carga la lista detallada de episodios (nombre y número)
    public func loadEpisodes() async {
        episodesState = .loading
        
        do {
            let details = try await getEpisodeDetailsUseCase.execute(episodeUrls: character.episodeUrls)
            episodesState = .success(details)
        } catch {
            AppLogger.error("Error al cargar episodios en el detalle", category: .presentation, error: error)
            episodesState = .error(error.localizedDescription)
        }
    }
    
    /// Marca o desmarca un episodio específico como visto
    public func toggleEpisodeWatched(episode: Episode) async {
        guard case .success(var currentEpisodes) = episodesState else { return }
        
        let newWatchedState = !episode.isWatched
        
        do {
            // Guardamos en la base de datos local (CoreData)
            try await markEpisodeWatchedUseCase.execute(episodeUrl: episode.url, isWatched: newWatchedState)
            
            // Actualizamos la lista local en memoria para refrescar la UI al instante
            if let index = currentEpisodes.firstIndex(where: { $0.id == episode.id }) {
                currentEpisodes[index].isWatched = newWatchedState
                episodesState = .success(currentEpisodes)
            }
        } catch {
            AppLogger.error("Error al cambiar estado de episodio visto", category: .presentation, error: error)
        }
    }
}
