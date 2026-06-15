//
//  CharacterListViewModel.swift
//  iOS-Rehearsal
//
//  Created by Rubén Suárez on 14/06/26.
//

import Foundation
import Combine

// MARK: - View State Enum
public enum CharacterListViewState: Equatable {
    case idle
    case loading
    case success([Character])
    case empty
    case error(String)
}

// MARK: - View Model
@MainActor
public final class CharacterListViewModel: ObservableObject {
    // MARK: - Properties
    
    private let getCharactersUseCase: GetCharactersUseCase
    private var cancellables = Set<AnyCancellable>()
    
    private var activeFetchTask: Task<Void, Never>?
    
    @Published public var viewState: CharacterListViewState = .idle
    @Published public var searchQuery: String = ""
    @Published public var selectedStatus: String = ""
    @Published public var selectedSpecies: String = ""
    
    // Control de paginación
    private var currentPage = 1
    private var canLoadMorePages = true
    private var isFetching = false
    private var allCharacters: [Character] = []
    
    // MARK: - Init
    
    public init(getCharactersUseCase: GetCharactersUseCase) {
        self.getCharactersUseCase = getCharactersUseCase
        setupSearchSubscription()
    }
    
    // MARK: - Setup Combine subscriptions
    
    private func setupSearchSubscription() {
        Publishers.CombineLatest3($searchQuery, $selectedStatus, $selectedSpecies)
            .debounce(for: .milliseconds(300), scheduler: RunLoop.main)
            .removeDuplicates { prev, current in
                return prev.0 == current.0 && prev.1 == current.1 && prev.2 == current.2
            }
            .sink { [weak self] name, status, species in
                guard let self = self else { return }
                self.activeFetchTask?.cancel()
                
                self.activeFetchTask = Task { [weak self] in
                    guard let self = self else { return }
                    await self.resetAndFetch(name: name, status: status, species: species)
                }
            }
            .store(in: &cancellables)
    }
    
    // MARK: - Network / Data Operations
    
    public func resetAndFetch(name: String? = nil, status: String? = nil, species: String? = nil) async {
        currentPage = 1
        canLoadMorePages = true
        allCharacters = []
        viewState = .loading
        
        await fetchCharacters(
            page: currentPage,
            name: name ?? searchQuery,
            status: status ?? selectedStatus,
            species: species ?? selectedSpecies
        )
    }
    
    public func refresh() async {
        activeFetchTask?.cancel()
        let task = Task { [weak self] in
            guard let self = self else { return }
            await self.resetAndFetch()
        }
        activeFetchTask = task
        await task.value
    }
    
    public func loadNextPage() async {
        guard canLoadMorePages, !isFetching else { return }
        
        let nextPage = currentPage + 1
        let task = Task { [weak self] in
            guard let self = self else { return }
            await self.fetchCharacters(
                page: nextPage,
                name: self.searchQuery,
                status: self.selectedStatus,
                species: self.selectedSpecies
            )
        }
        activeFetchTask = task
        await task.value
    }
    
    private func fetchCharacters(
        page: Int,
        name: String,
        status: String,
        species: String
    ) async {
        if Task.isCancelled { return }
        isFetching = true
        
        let nameQuery = name.isEmpty ? nil : name
        let statusQuery = status.isEmpty ? nil : status
        let speciesQuery = species.isEmpty ? nil : species
        
        do {
            let newCharacters = try await getCharactersUseCase.execute(
                page: page,
                name: nameQuery,
                status: statusQuery,
                species: speciesQuery
            )
            
            // OPTIMIZACIÓN: Verificamos si la tarea fue cancelada antes de actualizar la UI
            if Task.isCancelled {
                isFetching = false
                return
            }
            
            isFetching = false
            
            if page == 1 && newCharacters.isEmpty {
                allCharacters = []
                viewState = .empty
                canLoadMorePages = false
                return
            }
            
            if newCharacters.count < 20 {
                canLoadMorePages = false
            }
            
            // Concatenamos de forma defensiva para evitar duplicados en fallback de caché o traslapo
            for character in newCharacters {
                if !allCharacters.contains(where: { $0.id == character.id }) {
                    allCharacters.append(character)
                }
            }
            currentPage = page
            viewState = .success(allCharacters)
            
        } catch {
            isFetching = false
            
            if Task.isCancelled {
                return
            }
            
            AppLogger.error("Error en fetchCharacters del ViewModel", category: .presentation, error: error)
            
            if page == 1 {
                viewState = .error(error.localizedDescription)
            }
        }
    }
}
