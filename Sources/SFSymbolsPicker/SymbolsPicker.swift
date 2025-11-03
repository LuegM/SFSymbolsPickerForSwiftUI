//
//  SymbolsPicker.swift
//
//  Created by Alessio Rubicini on 22/10/23.
//

import SwiftUI
import SFSafeSymbols

public struct SymbolsPicker<Content: View>: View {
    
    @Binding var selection: String
    @ObservedObject var vm: SymbolsPickerViewModel
    @Environment(\.presentationMode) var presentationMode
    @State private var searchText = ""
    
    let closeButtonView: Content
    public var showsCloseButton: Bool   // ✅ New flag
    
    // MARK: - Initializer
    
    public init(
        selection: Binding<String>,
        title: Text,
        searchLabel: Text,
        autoDismiss: Bool = false,
        symbols: [SFSymbol] = [],
        showsCloseButton: Bool = true,   // ✅ New parameter (default = true)
        @ViewBuilder closeButton: () -> Content = { Image(systemName: "xmark.circle") }
    ) {
        self._selection = selection
        self.vm = SymbolsPickerViewModel(
            title: title,
            searchbarLabel: searchLabel,
            autoDismiss: autoDismiss,
            symbols: symbols
        )
        self.closeButtonView = closeButton()
        self.showsCloseButton = showsCloseButton
    }
    
    // MARK: - Body
    
    public var body: some View {
        NavigationStack {
            VStack {
                Group {
                    if vm.isLoading {
                        ProgressView()
                            .scaleEffect(1.2)
                            .frame(maxWidth: .infinity, maxHeight: .infinity)
                    } else if vm.symbols.isEmpty && !searchText.isEmpty {
                        ContentUnavailableView {
                            Label {
                                Text("No Symbols Found", bundle: .module)
                            } icon: {
                                Image(systemName: "magnifyingglass")
                            }
                        } description: {
                            Text("Try searching for something else", bundle: .module)
                        }
                    } else {
                        ScrollView(.vertical) {
                            LazyVGrid(
                                columns: [GridItem(.adaptive(minimum: 60, maximum: 80), spacing: 8)],
                                spacing: 8
                            ) {
                                ForEach(vm.symbols, id: \.hash) { icon in
                                    Button {
                                        withAnimation {
                                            self.selection = icon
                                        }
                                    } label: {
                                        SymbolIcon(symbolName: icon, selection: $selection)
                                    }
                                }
                                
                                if vm.hasMoreSymbols && searchText.isEmpty {
                                    if vm.isLoadingMore {
                                        ProgressView().padding()
                                    } else {
                                        Color.clear
                                            .frame(height: 1)
                                            .onAppear { vm.loadMoreSymbols() }
                                    }
                                }
                            }
                            .padding(8)
                        }
                        .scrollIndicators(.hidden)
                        .scrollDisabled(false)
                        #if !os(visionOS)
                        .scrollDismissesKeyboard(.immediately)
                        #endif
                    }
                }
                .navigationTitle(vm.title)
                #if os(iOS)
                .navigationBarTitleDisplayMode(.inline)
                #endif
                // ✅ Only show toolbar if enabled
                .toolbar {
                    if showsCloseButton {
                        ToolbarItem(placement: .cancellationAction) {
                            Button {
                                presentationMode.wrappedValue.dismiss()
                            } label: {
                                closeButtonView
                            }
                        }
                    }
                }
            }
            .searchable(text: $searchText, prompt: vm.searchbarLabel)
        }
        .onChange(of: selection) { _, newValue in
            if vm.autoDismiss {
                presentationMode.wrappedValue.dismiss()
            }
        }
        .onChange(of: searchText) { _, newValue in
            if newValue.isEmpty {
                vm.reset()
            } else {
                vm.searchSymbols(with: newValue)
            }
        }
    }
}

// MARK: - Convenience initializers

extension SymbolsPicker {
    
    public init(
        selection: Binding<String>,
        titleKey: LocalizedStringKey,
        searchLabel: LocalizedStringKey,
        bundle: Bundle = #bundle,
        autoDismiss: Bool = false,
        symbols: [SFSymbol] = [],
        showsCloseButton: Bool = true,
        @ViewBuilder closeButton: () -> Content = { Image(systemName: "xmark.circle") }
    ) {
        self._selection = selection
        self.vm = SymbolsPickerViewModel(
            title: Text(titleKey, bundle: bundle),
            searchbarLabel: Text(searchLabel, bundle: bundle),
            autoDismiss: autoDismiss,
            symbols: symbols
        )
        self.closeButtonView = closeButton()
        self.showsCloseButton = showsCloseButton
    }
    
    public init(
        selection: Binding<String>,
        titleKey: LocalizedStringKey,
        bundle: Bundle = #bundle,
        autoDismiss: Bool = false,
        symbols: [SFSymbol] = [],
        showsCloseButton: Bool = true,
        @ViewBuilder closeButton: () -> Content = { Image(systemName: "xmark.circle") }
    ) {
        self._selection = selection
        self.vm = SymbolsPickerViewModel(
            title: Text(titleKey, bundle: bundle),
            searchbarLabel: Text("Search...", bundle: .module),
            autoDismiss: autoDismiss,
            symbols: symbols
        )
        self.closeButtonView = closeButton()
        self.showsCloseButton = showsCloseButton
    }
    
    public init(
        selection: Binding<String>,
        title: String,
        searchLabel: String = "Search...",
        autoDismiss: Bool = false,
        symbols: [SFSymbol] = [],
        showsCloseButton: Bool = true,
        @ViewBuilder closeButton: () -> Content = { Image(systemName: "xmark.circle") }
    ) {
        self._selection = selection
        self.vm = SymbolsPickerViewModel(
            title: Text(title),
            searchbarLabel: Text(searchLabel),
            autoDismiss: autoDismiss,
            symbols: symbols
        )
        self.closeButtonView = closeButton()
        self.showsCloseButton = showsCloseButton
    }
}

#Preview {
    SymbolsPicker(
        selection: .constant("beats.powerbeatspro"),
        title: "Pick a symbol",
        autoDismiss: true,
        showsCloseButton: false // ✅ Example: hide close button
    )
}
