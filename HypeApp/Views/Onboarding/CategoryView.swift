import SwiftUI

struct CategoryView: View {
    @EnvironmentObject var viewModel: OnboardingViewModel

    let columns = [
        GridItem(.flexible()),
        GridItem(.flexible()),
    ]

    var body: some View {
        VStack(spacing: 0) {
            onboardingHeader(step: 5, total: 8) {
                viewModel.prevStep()
            }

            ScrollView {
                VStack(spacing: 32) {
                    VStack(spacing: 12) {
                        Text("What do you want to work on?")
                            .font(.system(size: 30, weight: .bold, design: .serif))
                            .foregroundColor(.white)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, 20)

                        Text("Pick as many as you like — your affirmations will be personalised")
                            .font(.system(size: 15))
                            .foregroundColor(.white.opacity(0.75))
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, 24)
                    }
                    .padding(.top, 20)

                    LazyVGrid(columns: columns, spacing: 12) {
                        ForEach(viewModel.availableCategories) { category in
                            CategoryChip(
                                category: category,
                                isSelected: viewModel.selectedCategories.contains(category.name),
                                action: { viewModel.toggleCategory(category.name) }
                            )
                            .frame(maxWidth: .infinity)
                        }
                    }
                    .padding(.horizontal, 24)
                }
                .padding(.bottom, 120)
            }
        }
        .overlay(alignment: .bottom) {
            VStack(spacing: 0) {
                LinearGradient(
                    colors: [Color.clear, Color.black.opacity(0.3)],
                    startPoint: .top,
                    endPoint: .bottom
                )
                .frame(height: 40)

                GradientButton(
                    title: "Continue (\(viewModel.selectedCategories.count) selected)",
                    action: { viewModel.nextStep() },
                    disabled: viewModel.selectedCategories.isEmpty
                )
                .padding(.horizontal, 32)
                .padding(.bottom, 52)
                .background(Color.clear)
            }
        }
        .onAppear {
            viewModel.loadCategories()
        }
    }
}
