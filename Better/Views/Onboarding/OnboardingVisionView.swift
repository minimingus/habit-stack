//
//  OnboardingVisionView.swift
//  Better You
//
//  Created by Symphony
//  Phase 2: Issue #18
//

import SwiftUI
import PostHog

/// Onboarding Screen 1: "Imagine Your Future Self"
struct OnboardingVisionView: View {
    @State private var showText = false
    @State private var pulseAnimation = false
    let onContinue: () -> Void
    
    var body: some View {
        VStack(spacing: 30) {
            Spacer()
            
            // Animated silhouette
            Image(systemName: "figure.walk")
                .font(.system(size: 100))
                .foregroundStyle(
                    LinearGradient(
                        colors: [.blue, .purple],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .scaleEffect(pulseAnimation ? 1.1 : 1.0)
                .opacity(pulseAnimation ? 0.8 : 1.0)
                .animation(
                    .easeInOut(duration: 2.0)
                        .repeatForever(autoreverses: true),
                    value: pulseAnimation
                )
            
            VStack(spacing: 16) {
                Text("Imagine yourself 90 days from now...")
                    .font(.title2)
                    .fontWeight(.semibold)
                    .multilineTextAlignment(.center)
                
                Text("A better version of you.\nWhat's different?")
                    .font(.body)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
            }
            .opacity(showText ? 1 : 0)
            .offset(y: showText ? 0 : 20)
            .animation(.easeIn(duration: 0.8).delay(0.5), value: showText)
            
            Spacer()
            
            Button(action: onContinue) {
                Text("Continue")
                    .font(.headline)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.accentColor)
                    .foregroundColor(.white)
                    .cornerRadius(12)
            }
            .opacity(showText ? 1 : 0)
            .animation(.easeIn(duration: 0.5).delay(1.3), value: showText)
        }
        .padding()
        .onAppear {
            showText = true
            pulseAnimation = true
            PostHogSDK.shared.capture("onboarding_started")
        }
    }
}

#Preview {
    OnboardingVisionView(onContinue: {})
}
