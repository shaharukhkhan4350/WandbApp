# Wandb iOS App

An iOS app for viewing Weights & Biases (wandb) training metrics and graphs on your iPhone.

## Features

- 🔐 Secure login with API key authentication
- 📊 View all your wandb projects
- 📈 Browse training runs
- 📉 Interactive training metrics graphs
- 🔒 Secure credential storage using Keychain

## Requirements

- iOS 16.0 or later
- Xcode 14.0 or later
- Swift 5.9 or later
- A wandb account with an API key

## Setup

1. **Get your wandb API key:**
   - Go to [wandb.ai/settings](https://wandb.ai/settings)
   - Navigate to the API keys section
   - Copy your API key

2. **Open the project:**
   - Open `WandbApp.xcodeproj` in Xcode
   - Build and run on a simulator or device

3. **Login:**
   - Enter your wandb entity (username or team name)
   - Enter your API key
   - Tap "Sign In"

## Project Structure

```
WandbApp/
├── WandbAppApp.swift          # Main app entry point
├── ContentView.swift           # Root view with navigation
├── Models/
│   ├── AuthenticationManager.swift
│   ├── KeychainHelper.swift
│   └── WandbModels.swift
├── Services/
│   └── WandbAPIService.swift
├── Views/
│   ├── LoginView.swift
│   ├── MainTabView.swift
│   ├── ProjectsView.swift
│   ├── RunsView.swift
│   ├── MetricsView.swift
│   └── SettingsView.swift
└── ViewModels/
    ├── ProjectsViewModel.swift
    ├── RunsViewModel.swift
    └── MetricsViewModel.swift
```

## Architecture

The app follows the MVVM (Model-View-ViewModel) architecture pattern:

- **Models**: Data structures and business logic
- **Views**: SwiftUI views for UI presentation
- **ViewModels**: Observable objects that manage state and business logic
- **Services**: API service layer for wandb integration

## API Integration

The app uses the wandb REST API to:
- Authenticate users
- Fetch projects
- Fetch runs for a project
- Fetch training metrics/history for runs

## Security

- API keys are stored securely in iOS Keychain
- Entity names are stored in UserDefaults (non-sensitive)
- All API communication uses HTTPS

## Charts

Training metrics are displayed using Swift Charts (available in iOS 16+), showing:
- Line charts for metric values over training steps
- Area charts with gradient fills
- Interactive chart views

## Future Enhancements

- [ ] Compare multiple runs side-by-side
- [ ] Filter and search runs
- [ ] Export metrics data
- [ ] Real-time updates for running experiments
- [ ] Dark mode support
- [ ] iPad optimization

## License

This project is for personal/educational use.
