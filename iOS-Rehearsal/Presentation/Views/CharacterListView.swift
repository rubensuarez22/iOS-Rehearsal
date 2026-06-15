import SwiftUI
import CoreData

// MARK: - Character List View
public struct CharacterListView: View {
    @ObservedObject var viewModel: CharacterListViewModel
    private let detailViewModelFactory: (Character) -> CharacterDetailViewModel
    
    // Lista de especies populares para el filtro rápido
    private let speciesList = ["", "Human", "Alien", "Humanoid", "Poopybutthole", "Mythological Creature", "Robot", "Cronenberg", "Disease", "unknown"]
    
    public init(
        viewModel: CharacterListViewModel,
        detailViewModelFactory: @escaping (Character) -> CharacterDetailViewModel
    ) {
        self.viewModel = viewModel
        self.detailViewModelFactory = detailViewModelFactory
    }
    
    public var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                filterBar
                
                Group {
                    switch viewModel.viewState {
                    case .idle, .loading:
                        loadingView
                    case .empty:
                        emptyStateView
                    case .error(let message):
                        errorView(message: message)
                    case .success(let characters):
                        listView(characters: characters)
                    }
                }
            }
            .navigationTitle("Personajes")
            .searchable(text: $viewModel.searchQuery, prompt: "Buscar personaje...")
            .refreshable {
                await viewModel.refresh()
            }
            .navigationDestination(for: Character.self) { character in
                CharacterDetailView(viewModel: detailViewModelFactory(character))
            }
        }
    }
    
    // MARK: - Componentes de Vista
    
    private var filterBar: some View {
        HStack(spacing: 12) {
            // Filtro de Estado
            Picker("Estado", selection: $viewModel.selectedStatus) {
                Text("Cualquiera").tag("")
                ForEach(CharacterStatus.allCases, id: \.self) { status in
                    Text(status.displayName).tag(status.rawValue)
                }
            }
            .pickerStyle(.menu)
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(Color(.systemGray6))
            .cornerRadius(8)
            
            // Filtro de Especie
            Picker("Especie", selection: $viewModel.selectedSpecies) {
                Text("Especie: Todas").tag("")
                ForEach(speciesList.filter { !$0.isEmpty }, id: \.self) { species in
                    Text(species == "unknown" ? "Desconocido" : species).tag(species)
                }
            }
            .pickerStyle(.menu)
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(Color(.systemGray6))
            .cornerRadius(8)
            
            Spacer()
        }
        .padding(.horizontal)
        .padding(.vertical, 8)
    }
    
    private var loadingView: some View {
        VStack {
            Spacer()
            ProgressView("Cargando personajes...")
                .scaleEffect(1.2)
            Spacer()
        }
    }
    
    private var emptyStateView: some View {
        VStack(spacing: 16) {
            Spacer()
            Image(systemName: "magnifyingglass")
                .font(.system(size: 60))
                .foregroundColor(.secondary)
            Text("No se encontraron personajes")
                .font(.headline)
            Text("Intenta ajustar los criterios de búsqueda o los filtros.")
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
            Spacer()
        }
        .padding()
    }
    
    private func errorView(message: String) -> some View {
        VStack(spacing: 16) {
            Spacer()
            Image(systemName: "exclamationmark.triangle")
                .font(.system(size: 60))
                .foregroundColor(.red)
            Text("Error al cargar datos")
                .font(.headline)
            Text(message)
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal)
            
            Button(action: {
                Task {
                    await viewModel.refresh()
                }
            }) {
                Text("Reintentar")
                    .fontWeight(.semibold)
                    .padding(.horizontal, 24)
                    .padding(.vertical, 12)
                    .background(Color.blue)
                    .foregroundColor(.white)
                    .cornerRadius(8)
            }
            Spacer()
        }
    }
    
    private func listView(characters: [Character]) -> some View {
        List {
            ForEach(characters) { character in
                NavigationLink(value: character) {
                    CharacterRowView(character: character)
                }
                .onAppear {
                    if character == characters.last {
                        Task {
                            await viewModel.loadNextPage()
                        }
                    }
                }
            }
        }
        .listStyle(.plain)
    }
}

// MARK: - Character Row View (Fila Estilizada)
public struct CharacterRowView: View {
    let character: Character
    
    public init(character: Character) {
        self.character = character
    }
    
    public var body: some View {
        HStack(spacing: 16) {
            // Imagen del Personaje
            CachedImage(urlString: character.image) { image in
                image
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .frame(width: 80, height: 80)
                    .clipped()
                    .cornerRadius(8)
            } placeholder: {
                ProgressView()
                    .frame(width: 80, height: 80)
            }
            
            VStack(alignment: .leading, spacing: 6) {
                // Nombre
                Text(character.name)
                    .font(.title3)
                    .fontWeight(.semibold)
                    .lineLimit(1)
                
                // Especie
                Text(character.species)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                
                // Estado (Píldora coloreada)
                HStack(spacing: 6) {
                    Circle()
                        .fill(statusColor(character.status))
                        .frame(width: 8, height: 8)
                    Text(character.status.displayName)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            
            Spacer()
            
            // Icono de favorito si corresponde
            if character.isFavorite {
                Image(systemName: "star.fill")
                    .foregroundColor(.yellow)
                    .font(.system(size: 18))
            }
        }
        .padding(.vertical, 4)
    }
    
    private func statusColor(_ status: CharacterStatus) -> Color {
        switch status {
        case .alive: return .green
        case .dead: return .red
        case .unknown: return .gray
        }
    }
}

#Preview {
    CharacterListView(
        viewModel: CharacterListViewModel(
            getCharactersUseCase: GetCharactersUseCase(
                repository: CharacterRepository(
                    apiClient: APIClient(),
                    container: PersistenceController.preview.container
                )
            )
        ),
        detailViewModelFactory: { character in
            let repo = CharacterRepository(
                apiClient: APIClient(),
                container: PersistenceController.preview.container
            )
            return CharacterDetailViewModel(
                character: character,
                toggleFavoriteUseCase: ToggleFavoriteUseCase(repository: repo),
                getEpisodeDetailsUseCase: GetEpisodeDetailsUseCase(repository: repo),
                markEpisodeWatchedUseCase: MarkEpisodeWatchedUseCase(repository: repo)
            )
        }
    )
}
