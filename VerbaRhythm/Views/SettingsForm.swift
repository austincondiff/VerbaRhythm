//
//  SettingsForm.swift
//  VerbaRhythm
//
//  Created by Austin Condiff on 8/27/24.
//

import SwiftUI

struct SettingsForm: View {
    @Environment(\.colorScheme) private var colorScheme
    @EnvironmentObject var settings: SettingsViewModel
    @EnvironmentObject var viewModel: ContentViewModel
    @State private var scrolledToTop: Bool = true

    var body: some View {
        Form {
            Group {
#if !os(macOS)
                Section {
                    EmptyView()
                } footer: {
                    Rectangle()
                        .frame(height: 0)
                        .background(
                            GeometryReader {
                                Color.clear.preference(
                                    key: ViewOffsetKey.self,
                                    value: -$0.frame(in: .named("scroll")).origin.y
                                )
                            }
                        )
                        .onPreferenceChange(ViewOffsetKey.self) {
                            if $0 <= -444.0 && !scrolledToTop {
                                withAnimation {
                                    scrolledToTop = true
                                }
                            } else if $0 > -444.0 && scrolledToTop {
                                scrolledToTop = false
                            }
                        }
                }
#endif

                // Access SettingsViewModel directly
                Section {
                    Toggle(isOn: $settings.showGhostText) {
                        Label("Ghost Text", systemImage: "eyes")
                    }
                    Toggle(isOn: $settings.showGuides) {
                        Label("Guides", systemImage: "eye.fill")
                    }
                }

                Section {
                    Slider(value: $settings.speedMultiplier,
                           in: 0.25...4,
                        minimumValueLabel: Image(systemName: "tortoise.fill"),
                        maximumValueLabel: Image(systemName: "hare.fill"),
                        label: {
                            Text("Speed")
                        }
                    )
                    Toggle(isOn: $settings.isDynamicSpeedOn) {
                        Label("Dynamic Speed", systemImage: "speedometer")
                    }
                } header: {
                  Text("Speed")
                } footer: {
                    Text("Automatically adjust the speed for each word based on the number of syllables and punctuation.")
                }

                Section {
                    Slider(value: $settings.fontSize,
                           in: 20...48,
                        minimumValueLabel: Image(systemName: "textformat.size.smaller"),
                        maximumValueLabel: Image(systemName: "textformat.size.larger"),
                        label: {
                            Text("Font Size")
                        }
                    )

                    Picker(selection: $settings.fontStyle) {
                        ForEach(TextStyle.allCases, id: \.self) { style in
                            Text(style.rawValue)
                                .tag(style)
                        }
                    } label: {
                        Label("Font Style", systemImage: "paintbrush.fill")
                    }
                    .pickerStyle(.menu)
                    .tint(.primary)

                    Picker(selection: $settings.fontWeight) {
                        ForEach(TextWeight.allCases, id: \.self) { weight in
                            Text(weight.rawValue)
                                .tag(weight)
                        }
                    } label: {
                        Label("Font Weight", systemImage: "lineweight")
                    }
                    .pickerStyle(.menu)
                    .tint(.primary)

                    if settings.fontStyle == .sansSerif {
                        Picker(selection: $settings.fontWidth) {
                            ForEach(TextWidth.allCases, id: \.self) { width in
                                Text(width.rawValue)
                                    .tag(width)
                            }
                        } label: {
                            Label("Font Width", systemImage: "arrow.left.and.right")
                        }
                        .pickerStyle(.menu)
                        .tint(.primary)
                    }
                } header: {
                    Text("Font")
                }

                Section {
                    Button(role: .destructive) {
                        viewModel.settingsResetConfirmationIsPresented = true
                    } label: {
                        Text("Reset All Settings")
                            .frame(maxWidth: .infinity, alignment: .center)
                            .multilineTextAlignment(.center)
                    }
                } footer: {
                    #if !os(macOS)
                    Color.clear
                        .padding(.bottom)
                    #endif
                }
            }
            #if os(iOS)
            .listRowBackground(colorScheme == .dark ? Color(.tertiarySystemGroupedBackground) : nil)
            #endif
            .labelStyle(.titleOnly)
        }
#if !os(macOS)
        .ignoresSafeArea()
        .safeAreaInset(edge: .top, spacing: 0) {
            VStack(spacing: 0) {
                HStack {
                    Text("Settings")
                        .font(.title3)
                        .bold()
                    Spacer()
                    Button(action: {
                        viewModel.settingsSheetIsPresented = false
                    }, label: {
                        ZStack {
                            Circle()
                                .fill(.secondary.opacity(0.4))
                                .frame(width: 30, height: 30)

                            Image(systemName: "xmark")
                                .font(.system(size: 15, weight: .bold, design: .rounded))
                                .foregroundColor(.secondary)
                        }
                        .contentShape(Circle())
                    })
                    .buttonStyle(PlainButtonStyle())
                    .accessibilityLabel(Text("Close"))
                }
                .padding(.vertical)
                .padding(.horizontal, 20)
                Rectangle()
                    #if os(macOS)
                    .fill(Color(.separatorColor))
                    #else
                    .fill(Color(.separator))
                    #endif
                    .frame(height: 0.33)
                    .opacity(1)
            }
            .background(.thickMaterial.opacity(scrolledToTop ? 0 : 1))
        }
#endif
        .confirmationDialog(
            "Reset All Settings",
            isPresented: $viewModel.settingsResetConfirmationIsPresented,
            titleVisibility: .hidden,
            actions: {
                Button(role: .destructive) {
                    settings.resetToDefaults()
                    viewModel.settingsResetConfirmationIsPresented = false
                } label: {
                    Text("Reset")
                }
                Button("Cancel", role: .cancel) {
                    viewModel.settingsResetConfirmationIsPresented = false
                }
            },
            message: {
                Text("All settings will be reset. This action cannot be undone.")
            }
        )
        .coordinateSpace(name: "scroll")
        .scrollContentBackground(colorScheme == .dark ? .hidden : .visible)
        .presentationDetents([.medium, .fraction(0.56)])
        .presentationDragIndicator(.visible)
        .presentationBackgroundInteraction(.enabled)
    }

    func removeTrailingZeros(_ number: Double) -> String {
        let formatter = NumberFormatter()
        formatter.minimumFractionDigits = 0
        formatter.maximumFractionDigits = 6 // Adjust this based on the precision you want
        formatter.numberStyle = .decimal

        return formatter.string(from: NSNumber(value: number)) ?? "\(number)"
    }
}

struct ViewOffsetKey: PreferenceKey {
    typealias Value = CGFloat
    static var defaultValue = CGFloat.zero
    static func reduce(value: inout Value, nextValue: () -> Value) {
        value += nextValue()
    }
}


//struct SettingsView: View {
//    @EnvironmentObject var viewModel: ContentViewModel
//    @State private var scrolledToTop: Bool = true
//
//    var body: some View {
//        ScrollView {
//            VStack {
//                VRFormSection {
//                    VRFormField("Ghost Text") {
//                        Toggle("Ghost Text", isOn: $viewModel.showGhostText)
//                    }
//                }
//
//                VRFormSection {
//                    VRFormField("Speed") {
//                        Picker("Speed", selection: $viewModel.speedMultiplier) {
//                            ForEach(viewModel.speedOptions, id: \.self) { speed in
//                                Text(String(format: "%.2fx", speed))
//                                    .tag(speed)
//                            }
//                        }
//                        .pickerStyle(.menu)
//                        .tint(.primary)
//                        .padding(.trailing, -12)
//                    }
//                    VRFormField("Dynamic Speed") {
//                        Toggle("Dynamic Speed", isOn: $viewModel.isDynamicSpeedOn)
//                    }
//                }
//
//                VRFormSection {
//                    VRFormField("Font Style") {
//                        Picker("Font Style", selection: $viewModel.fontStyle) {
//                            ForEach(TextStyle.allCases, id: \.self) { style in
//                                Text(style.rawValue)
//                                    .tag(style)
//                            }
//                        }
//                        .pickerStyle(.menu)
//                        .tint(.primary)
//                        .padding(.trailing, -12)
//                    }
//
//                    VRFormField("Font Size") {
//                        Picker("Font Size", selection: $viewModel.fontSize) {
//                            ForEach(TextSize.allCases, id: \.self) { size in
//                                Text(size.rawValue)
//                                    .tag(size)
//                            }
//                        }
//                        .pickerStyle(.menu)
//                        .tint(.primary)
//                        .padding(.trailing, -12)
//                    }
//
//                    VRFormField("Font Weight") {
//                        Picker("Font Weight", selection: $viewModel.fontWeight) {
//                            ForEach(TextWeight.allCases, id: \.self) { weight in
//                                Text(weight.rawValue)
//                                    .tag(weight)
//                            }
//                        }
//                        .pickerStyle(.menu)
//                        .tint(.primary)
//                        .padding(.trailing, -12)
//                    }
//                    VRFormField("Font Width") {
//                        Picker("Font Width", selection: $viewModel.fontWidth) {
//                            ForEach(TextWidth.allCases, id: \.self) { width in
//                                Text(width.rawValue)
//                                    .tag(width)
//                            }
//                        }
//                        .pickerStyle(.menu)
//                        .tint(.primary)
//                        .padding(.trailing, -12)
//                    }
//                }
//            }
//            .padding(.horizontal)
//            .safeAreaInset(edge: .top, spacing: 0) {
//                Rectangle()
//                    .frame(height: 0)
//                    .background(
//                        GeometryReader {
//                            Color.clear.preference(
//                                key: ViewOffsetKey.self,
//                                value: -$0.frame(in: .named("scroll")).origin.y
//                            )
//                        }
//                    )
//                    .onPreferenceChange(ViewOffsetKey.self) {
//                        print($0)
//                        if $0 <= 5.0 && !scrolledToTop {
//                            withAnimation {
//                                scrolledToTop = true
//                            }
//                        } else if $0 > 5.0 && scrolledToTop {
//                            scrolledToTop = false
//                        }
//                    }
//            }
//        }
//        .coordinateSpace(name: "scroll")
//        .safeAreaInset(edge: .top, spacing: 0) {
//            #if os(iOS)
//            VStack(spacing: 0) {
//                HStack {
//                    Text("Settings")
//                        .font(.title3)
//                        .bold()
//                    Spacer()
//                    Button(action: {
//                        viewModel.settingsSheetIsPresented = false
//                    }, label: {
//                        ZStack {
//                            Circle()
//                                .fill(Color(.secondarySystemBackground))
//                                .frame(width: 30, height: 30)
//
//                            Image(systemName: "xmark")
//                                .font(.system(size: 15, weight: .bold, design: .rounded))
//                                .foregroundColor(.secondary)
//                        }
//                        .contentShape(Circle())
//                    })
//                    .buttonStyle(PlainButtonStyle())
//                    .accessibilityLabel(Text("Close"))
//                }
//                .padding()
//                Rectangle()
//                    .fill(Color(.separator))
//                    .frame(height: 0.33)
//                    .opacity(scrolledToTop ? 0 : 1)
//            }
//            .background(.thickMaterial.opacity(scrolledToTop ? 0 : 1))
//            #endif
//        }
//        .frame(maxHeight: .infinity)
//        .presentationDetents([.medium, .large])
//        .presentationDragIndicator(.visible)
//        .presentationBackgroundInteraction(.enabled)
//    }
//}

//struct VRFormSection<Content: View>: View {
//    let content: Content
//
//    init(@ViewBuilder content: () -> Content) {
//        self.content = content()
//    }
//
//    var body: some View {
//        VStack(spacing: 0) {
//            Divided {
//                content
//            }
//        }
//        .background(Color(.secondarySystemBackground))
//        .clipShape(RoundedRectangle(cornerRadius: 10))
//    }
//}
//
//struct VRFormField<Content: View>: View {
//    let content: Content
//    let label: String
//
//    init(_ label: String, @ViewBuilder content: () -> Content) {
//        self.label = label
//        self.content = content()
//    }
//
//    var body: some View {
//        VStack {
//            LabeledContent(label) {
//                content
//                    .labelsHidden()
//            }
//        }
//        .frame(minHeight: 44)
//        .padding(.horizontal, 20)
//    }
//}
//
//struct Divided<Content: View>: View {
//    var content: Content
//
//    init(@ViewBuilder content: () -> Content) {
//        self.content = content()
//    }
//
//    var body: some View {
//        _VariadicView.Tree(DividedLayout()) {
//            content
//        }
//    }
//
//    struct DividedLayout: _VariadicView_MultiViewRoot {
//        @ViewBuilder
//        func body(children: _VariadicView.Children) -> some View {
//            let last = children.last?.id
//
//            ForEach(children) { child in
//                child
//
//                if child.id != last {
//                    Rectangle()
//                        .fill(Color(.separator))
//                        .frame(height: 0.33)
//                        .padding(.leading, 20)
//                }
//            }
//        }
//    }
//}

#Preview {
    SettingsForm()
}
