//
//  SwipeToCloseModifier.swift
//  Miru Browser
//
//  Created by Kevin Dutra on 12/6/25.
//

import SwiftUI
import UIKit

// MARK: - Swipe to Close Container View

struct SwipeToCloseContainer<Content: View>: View {
  let content: Content
  let onClose: () -> Void
  
  @State private var dragOffset: CGFloat = 0
  @State private var isClosing: Bool = false
  @State private var hasReachedThreshold: Bool = false
  
  // Constants
  private let closeThreshold: CGFloat = UIScreen.main.bounds.width * 0.4
  private let maxRotation: Double = -8
  
  // Computed properties
  private var progress: CGFloat {
    guard dragOffset < 0 else { return 0 }
    return min(abs(dragOffset) / closeThreshold, 1.0)
  }
  
  private var redBackgroundOpacity: Double {
    // Fade out during close animation
    if isClosing { return 0 }
    // Accelerate the red fade - starts subtle, ramps up quickly
    return Double(pow(progress, 0.7))
  }
  
  private var rotation: Double {
    maxRotation * Double(progress)
  }
  
  private var scale: CGFloat {
    isClosing ? 0.7 : 1.0 - (progress * 0.15)
  }
  
  private var contentOpacity: Double {
    isClosing ? 0 : 1.0
  }
  
  var body: some View {
    GeometryReader { geometry in
      ZStack {
        // Red background that fades in and out
        Color.red
          .opacity(redBackgroundOpacity)
          .animation(.easeOut(duration: 0.25), value: isClosing)
          .ignoresSafeArea()
        
        // Close indicator icon - appears as you swipe
        if progress > 0.15 && !isClosing {
          Image(systemName: "xmark.circle.fill")
            .font(.system(size: 56, weight: .medium))
            .foregroundStyle(.white.opacity(0.9))
            .scaleEffect(0.6 + (progress * 0.5))
            .opacity(Double(progress))
        }
        
        // Main content
        content
          .offset(x: isClosing ? -geometry.size.width : dragOffset)
          .rotationEffect(.degrees(rotation), anchor: .bottomTrailing)
          .scaleEffect(scale, anchor: .trailing)
          .opacity(contentOpacity)
      }
      .contentShape(Rectangle())
      .highPriorityGesture(
        DragGesture(minimumDistance: 30, coordinateSpace: .local)
          .onChanged { value in
            // Detect if this is primarily a horizontal gesture
            let horizontalDistance = abs(value.translation.width)
            let verticalDistance = abs(value.translation.height)
            
            // Only activate for horizontal-dominant left swipes
            guard horizontalDistance > verticalDistance * 1.5,
                  value.translation.width < 0,
                  !isClosing else { return }
            
            // Apply resistance as we approach threshold
            let rawOffset = value.translation.width
            let resistanceFactor: CGFloat = 0.8
            dragOffset = rawOffset * resistanceFactor
            
            // Track if threshold has been reached (haptic feedback once)
            if abs(dragOffset) >= closeThreshold && !hasReachedThreshold {
              hasReachedThreshold = true
              let generator = UIImpactFeedbackGenerator(style: .medium)
              generator.impactOccurred()
            } else if abs(dragOffset) < closeThreshold {
              hasReachedThreshold = false
            }
          }
          .onEnded { value in
            guard !isClosing else { return }
            
            // Close if threshold was reached, otherwise spring back
            if hasReachedThreshold {
              triggerClose(screenWidth: geometry.size.width)
            } else {
              withAnimation(.spring(response: 0.35, dampingFraction: 0.75)) {
                dragOffset = 0
              }
            }
            hasReachedThreshold = false
          }
      )
    }
  }
  
  private func triggerClose(screenWidth: CGFloat) {
    isClosing = true
    
    // Animate off screen
    withAnimation(.easeOut(duration: 0.25)) {
      dragOffset = -screenWidth
    }
    
    // Call close after animation
    DispatchQueue.main.asyncAfter(deadline: .now() + 0.25) {
      onClose()
      
      // Reset state
      dragOffset = 0
      isClosing = false
    }
  }
}

// MARK: - View Extension

extension View {
  func swipeToClose(onClose: @escaping () -> Void) -> some View {
    SwipeToCloseContainer(content: self, onClose: onClose)
  }
}

