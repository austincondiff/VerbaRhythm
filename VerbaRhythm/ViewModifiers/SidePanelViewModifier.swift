//
//  SidePanelViewModifier.swift
//  Verbarhythm
//
//  Created by Austin Condiff on 8/18/24.
//

import SwiftUI

struct SidePanelModifier<PanelContent: View>: ViewModifier {
    @Binding var isPresented: Bool

    let panelContent: () -> PanelContent

    @State private var dragOffset: CGFloat = 0

    @State private var sidePanelIsPresented = false

    private let sidePanelInset: CGFloat = 64

    func body(content: Content) -> some View {
        GeometryReader { proxy in
            let sidePanelWidth = proxy.size.width - sidePanelInset

            content
                .opacity(calculateContentOpacity(proxy: proxy))
                .gesture(
                    sidePanelIsPresented ? TapGesture().onEnded {
                        withAnimation {
                            sidePanelIsPresented = false
                        }
                    } : nil
                )
                .background(alignment: .leading) {
                    panelContent()
                        .padding(.trailing, 64)
                        .frame(width: max(0, proxy.size.width))
                        .frame(maxHeight: .infinity)
                        .background(Color(.secondarySystemBackground))
                        .mask(
                            ZStack {
                                Rectangle()
                                    .ignoresSafeArea()
                                Path(
                                    roundedRect: CGRect(
                                        x: 0,
                                        y: 0,
                                        width: proxy.size.width,
                                        height: proxy.size.height+proxy.safeAreaInsets.top+proxy.safeAreaInsets.bottom
                                    ),
                                    cornerSize: CGSize(width: 30, height: 30)
                                )
                                .ignoresSafeArea()
                                .blendMode(.destinationOut)
                                .offset(x: max(0, sidePanelWidth))
                            }
                            .compositingGroup()
                        )
                        .offset(x: -sidePanelWidth)
                }

                .offset(x: calculatePanelOffset(proxy: proxy))
                .gesture(dragGesture(proxy: proxy))
                .onChange(of: isPresented) { newValue in
                    withAnimation {
                        dragOffset = 0
                        sidePanelIsPresented = newValue
                    }
                }
                .onChange(of: sidePanelIsPresented) { newValue in
                    if newValue != isPresented {
                        isPresented = newValue
                    }
                }
        }
    }

    private func dragGesture(proxy: GeometryProxy) -> some Gesture {
        DragGesture()
            .onChanged { value in
                let sidePanelWidth = proxy.size.width - sidePanelInset

                if sidePanelIsPresented {
                    dragOffset = max(1, min(sidePanelWidth, sidePanelWidth + value.translation.width))
                } else {
                    dragOffset = min(max(0, value.translation.width), sidePanelWidth)
                }
            }
            .onEnded { value in
                let sidePanelWidth = proxy.size.width - sidePanelInset
                let threshold = sidePanelWidth / 2

                if (!sidePanelIsPresented && value.translation.width > threshold)
                    || (sidePanelIsPresented && value.translation.width > -threshold) {
                    withAnimation {
                        sidePanelIsPresented = true
                        dragOffset = sidePanelWidth
                    }
                } else {
                    withAnimation {
                        sidePanelIsPresented = false
                        dragOffset = 0
                    }
                }
            }
    }

    private func calculateContentOpacity(proxy: GeometryProxy) -> Double {
        let sidePanelWidth = proxy.size.width - sidePanelInset

        if sidePanelIsPresented {
            return dragOffset == 0
                ? 0.5
                : 1 - (min(max(0, dragOffset), sidePanelWidth) / (sidePanelWidth) * 0.5)
        }

        return 1 - (min(max(0, dragOffset), sidePanelWidth) / (sidePanelWidth) * 0.5)
    }

    private func calculatePanelOffset(proxy: GeometryProxy) -> CGFloat {
        let sidePanelWidth = proxy.size.width - sidePanelInset

        if sidePanelIsPresented {
            return dragOffset == 0 ? sidePanelWidth : dragOffset
        }

        return min(max(0, dragOffset), sidePanelWidth)
    }
}

extension View {
    func sidePanel<PanelContent: View>(
        isPresented: Binding<Bool>,
        @ViewBuilder panelContent: @escaping () -> PanelContent
    ) -> some View {
        self.modifier(SidePanelModifier(isPresented: isPresented, panelContent: panelContent))
    }
}
