import SwiftUI

public struct SearchView: View {
    @State private var query = ""
    @State private var results: [AstryxSearchResult] = []
    @Environment(\.searchEngine) private var searchEngine
    
    public init() {}
    
    public var body: some View {
        VStack {
            TextField("Search songs, artists, albums...", text: $query)
                .textFieldStyle(.roundedBorder)
                .padding()
                .onChange(of: query) { newValue in
                    Task {
                        results = await searchEngine.search(query: SearchQuery(text: newValue))
                    }
                }
            
            List(results, id: \.id) { result in
                VStack(alignment: .leading) {
                    Text(result.title).font(AstryxTypography.Label.medium)
                    Text(result.subtitle).font(AstryxTypography.Body.small)
                }
            }
        }
    }
}
