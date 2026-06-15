import SwiftUI
import CoreData

// MARK: - Favorites View
public struct FavoritesView: View {
    @ObservedObject var viewModel: FavoritesViewModel
    private let detailViewModelFactory: (Character) -> CharacterDetailViewModel
    
    public init(
        viewModel: FavoritesViewModel,
        detailViewModelFactory: @escaping (Character) -> CharacterDetailViewModel
    ) {
        self.viewModel = viewModel
        self.detailViewModelFactory = detailViewModelFactory
    }
    
    public var body: some View {
        NavigationStack {
            Group {
                if !viewModel.isAuthenticated {
                    // Pantalla de Bloqueo por Face ID
                    lockedView
                } else {
                    // Contenido desbloqueado
                    unlockedContentView
                }
            }
            .navigationTitle("Favoritos")
            // Intenta autenticar automáticamente al entrar a la pantalla
            .task {
                if !viewModel.isAuthenticated {
                    await viewModel.authenticateAndLoad()
                } else {
                    await viewModel.loadFavorites()
                }
            }
            .navigationDestination(for: Character.self) { character in
                CharacterDetailView(viewModel: detailViewModelFactory(character))
            }
        }
    }
    
    // MARK: - Vistas de Seguridad (Bloqueo)
    
    private var lockedView: some View {
        VStack(spacing: 24) {
            Spacer()
            
            // Icono de Candado Estilizado
            ZStack {
                Circle()
                    .fill(Color.blue.opacity(0.1))
                    .frame(width: 120, height: 120)
                Image(systemName: "lock.fill")
                    .font(.system(size: 50))
                    .foregroundColor(.blue)
            }
            
            VStack(spacing: 8) {
                Text("Pantalla Bloqueada")
                    .font(.title2)
                    .fontWeight(.bold)
                Text("Se requiere Face ID o Touch ID para acceder a tus favoritos guardados.")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 32)
            }
            
            // Mostrar error si la biometría falló
            if let error = viewModel.authError {
                Text(error)
                    .font(.caption)
                    .foregroundColor(.red)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 32)
            }
            
            // Botón para volver a intentar autenticar
            Button(action: {
                Task {
                    await viewModel.authenticateAndLoad()
                }
            }) {
                HStack(spacing: 8) {
                    Image(systemName: "faceid")
                    Text("Desbloquear con Face ID")
                        .fontWeight(.semibold)
                }
                .padding(.horizontal, 24)
                .padding(.vertical, 14)
                .background(Color.blue)
                .foregroundColor(.white)
                .cornerRadius(12)
                .shadow(color: Color.blue.opacity(0.3), radius: 8, x: 0, y: 4)
            }
            
            Spacer()
        }
        .padding()
    }
    
    // MARK: - Vistas de Contenido Desbloqueado
    
    @ViewBuilder
    private var unlockedContentView: some View {
        VStack {
            switch viewModel.viewState {
            case .idle, .loading:
                loadingView
            case .error(let message):
                errorView(message: message)
            case .success(let favorites):
                if favorites.isEmpty {
                    emptyFavoritesView
                } else {
                    favoritesListView(favorites: favorites)
                }
            }
        }
        .toolbar {
            // Botón en la barra superior para volver a bloquear manualmente la pantalla
            ToolbarItem(placement: .navigationBarTrailing) {
                Button(action: {
                    viewModel.lock()
                }) {
                    Image(systemName: "lock.open.fill")
                        .foregroundColor(.blue)
                }
            }
        }
    }
    
    private var loadingView: some View {
        VStack {
            Spacer()
            ProgressView("Cargando favoritos...")
                .scaleEffect(1.2)
            Spacer()
        }
    }
    
    private func errorView(message: String) -> some View {
        VStack(spacing: 16) {
            Spacer()
            Image(systemName: "exclamationmark.triangle")
                .font(.system(size: 50))
                .foregroundColor(.red)
            Text("Error al cargar favoritos")
                .font(.headline)
            Text(message)
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
            
            Button(action: {
                Task {
                    await viewModel.loadFavorites()
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
        .padding()
    }
    
    private var emptyFavoritesView: some View {
        VStack(spacing: 16) {
            Spacer()
            Image(systemName: "star.slash")
                .font(.system(size: 60))
                .foregroundColor(.secondary)
            Text("No tienes favoritos guardados")
                .font(.headline)
            Text("Ve al listado principal de personajes, selecciona uno, y márcalo como favorito con la estrella.")
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 32)
            Spacer()
        }
        .padding()
    }
    
    private func favoritesListView(favorites: [Character]) -> some View {
        List {
            ForEach(favorites) { character in
                NavigationLink(value: character) {
                    CharacterRowView(character: character)
                }
            }
        }
        .listStyle(.plain)
    }
}

#Preview {
    let repo = CharacterRepository(apiClient: APIClient(), container: PersistenceController.preview.container)
    return FavoritesView(
        viewModel: FavoritesViewModel(
            authenticateBiometricsUseCase: AuthenticateBiometricsUseCase(authenticator: BiometricAuthenticator()),
            getFavoritesUseCase: GetFavoritesUseCase(repository: repo)
        ),
        detailViewModelFactory: { character in
            return CharacterDetailViewModel(
                character: character,
                toggleFavoriteUseCase: ToggleFavoriteUseCase(repository: repo),
                getEpisodeDetailsUseCase: GetEpisodeDetailsUseCase(repository: repo),
                markEpisodeWatchedUseCase: MarkEpisodeWatchedUseCase(repository: repo)
            )
        }
    )
}
