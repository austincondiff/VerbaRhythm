//
//  SidePanelViewModifier.swift
//  Verbarhythm
//
//  Created by Austin Condiff on 8/18/24.
//

import SwiftUI

struct SidePanelModifier<PanelContent: View>: ViewModifier {
    @Binding var isPresented: Bool {
        didSet {
            dragOffset = 0
        }
    }

    let panelContent: () -> PanelContent

    @State private var dragOffset: CGFloat = 0

    func body(content: Content) -> some View {
        GeometryReader { proxy in
            content
                .opacity(calculateContentOpacity(proxy: proxy))
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
                                .offset(x: max(0, proxy.size.width - 64))
                            }
                            .compositingGroup()
                        )
                        .offset(x: -proxy.size.width + 64)
                }
                .gesture(
                    isPresented ? TapGesture().onEnded {
                        isPresented = false
                    } : nil
                )
                .offset(x: calculatePanelOffset(proxy: proxy))
                .gesture(dragGesture(proxy: proxy))
                .animation(.easeInOut, value: isPresented)
        }
    }

    private func dragGesture(proxy: GeometryProxy) -> some Gesture {
        DragGesture()
            .onChanged { value in
                let sidePanelWidth = proxy.size.width - 64

//                if isPlaying {
//                    pause()
//                }

                if isPresented {
                    dragOffset = max(1, min(sidePanelWidth, sidePanelWidth + value.translation.width))
                } else {
                    dragOffset = min(max(0, value.translation.width), sidePanelWidth)
                }
            }
            .onEnded { value in
                let sidePanelWidth = proxy.size.width - 64
                let threshold = sidePanelWidth / 2

                if (!isPresented && value.translation.width > threshold) 
                    || (isPresented && value.translation.width > -threshold) {
                    withAnimation {
                        isPresented = true
                    }
                    dragOffset = sidePanelWidth
                } else {
                    withAnimation {
                        isPresented = false
                        dragOffset = 0
                    }
                }
            }
    }

    private func calculateContentOpacity(proxy: GeometryProxy) -> Double {
        let sidePanelWidth = proxy.size.width - 64

        if isPresented {
            return dragOffset == 0
                ? 0.5
                : 1 - (min(max(0, dragOffset), sidePanelWidth) / (sidePanelWidth) * 0.5)
        }

        return 1 - (min(max(0, dragOffset), sidePanelWidth) / (sidePanelWidth) * 0.5)
    }

    private func calculatePanelOffset(proxy: GeometryProxy) -> CGFloat {
        let sidePanelWidth = proxy.size.width - 64

        if isPresented {
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
