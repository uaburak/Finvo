//
//  CustomTabBar.swift
//  CustomGlassTabBar
//
//  Created by Balaji Venkatesh on 28/09/25.
//  Optimized for consistent colors and performance
//

import SwiftUI

struct CustomTabBar<TabItemView: View>: UIViewRepresentable {
    var size: CGSize
    var activeTint: Color = .blue
    var inActiveTint: Color = .primary
    var barTint: Color = .gray.opacity(0.2)
    @Binding var activeTab: CustomTab
    @ViewBuilder var tabItemView: (CustomTab) -> TabItemView
    @Environment(\.colorScheme) private var colorScheme
    
    func makeCoordinator() -> Coordinator {
        Coordinator(parent: self)
    }
    
    func makeUIView(context: Context) -> UIView {
        let items = CustomTab.allCases.map(\.rawValue)
        let control = UISegmentedControl(items: items)
        control.selectedSegmentIndex = activeTab.index
        
        // Render tab items as images with FIXED colors
        for (index, tab) in CustomTab.allCases.enumerated() {
            // Create the view with explicit color based on selection state
            let isSelected = tab.index == activeTab.index
            let tint = isSelected ? activeTint : inActiveTint
            
            let coloredView = tabItemView(tab)
                .foregroundStyle(tint)
                .environment(\.colorScheme, colorScheme) // Use current color scheme
            
            let renderer = ImageRenderer(content: coloredView)
            renderer.scale = UIScreen.main.scale
            
            if let uiImage = renderer.uiImage {
                // Use alwaysOriginal to prevent UIKit tint overlay
                let finalImage = uiImage.withRenderingMode(.alwaysOriginal)
                control.setImage(finalImage, forSegmentAt: index)
            }
        }
        
        // Hide default segment images (optimization)
        DispatchQueue.main.async {
            for subview in control.subviews {
                if subview is UIImageView && subview != control.subviews.last {
                    subview.alpha = 0
                }
            }
        }
        
        // Style configuration
        control.selectedSegmentTintColor = UIColor(barTint)
        control.backgroundColor = .clear
        
        // Add target for selection changes
        control.addTarget(context.coordinator, action: #selector(context.coordinator.tabSelected(_:)), for: .valueChanged)
        
        // Store reference for updates
        context.coordinator.segmentedControl = control
        
        // Container for padding
        let container = UIView()
        container.backgroundColor = .clear
        container.addSubview(control)
        control.translatesAutoresizingMaskIntoConstraints = false
        
        NSLayoutConstraint.activate([
            control.topAnchor.constraint(equalTo: container.topAnchor, constant: 2),
            control.bottomAnchor.constraint(equalTo: container.bottomAnchor, constant: -3),
            control.leadingAnchor.constraint(equalTo: container.leadingAnchor, constant: 2),
            control.trailingAnchor.constraint(equalTo: container.trailingAnchor, constant: -2)
        ])
        
        return container
    }
    
    func updateUIView(_ uiView: UIView, context: Context) {
        guard let control = context.coordinator.segmentedControl else { return }
        
        // Only update if selection actually changed
        if control.selectedSegmentIndex != activeTab.index {
            control.selectedSegmentIndex = activeTab.index
        }
        
        // Re-render images with updated colors
        for (index, tab) in CustomTab.allCases.enumerated() {
            let isSelected = tab.index == activeTab.index
            let tint = isSelected ? activeTint : inActiveTint
            
            let coloredView = tabItemView(tab)
                .foregroundStyle(tint)
                .environment(\.colorScheme, colorScheme)
            
            let renderer = ImageRenderer(content: coloredView)
            renderer.scale = UIScreen.main.scale
            
            if let uiImage = renderer.uiImage {
                let finalImage = uiImage.withRenderingMode(.alwaysOriginal)
                control.setImage(finalImage, forSegmentAt: index)
            }
        }
    }
    
    func sizeThatFits(_ proposal: ProposedViewSize, uiView: UIView, context: Context) -> CGSize? {
        return size
    }
    
    class Coordinator: NSObject {
        var parent: CustomTabBar
        weak var segmentedControl: UISegmentedControl?
        
        init(parent: CustomTabBar) {
            self.parent = parent
        }
        
        @objc func tabSelected(_ control: UISegmentedControl) {
            let newTab = CustomTab.allCases[control.selectedSegmentIndex]
            if parent.activeTab != newTab {
                parent.activeTab = newTab
            }
        }
    }
}

#Preview {
    ContentView()
        .environmentObject(AuthenticationManager.shared)
        .environmentObject(WalletManager.shared)
}
