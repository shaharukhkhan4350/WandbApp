# Wandb iOS App - Setup Guide

## Quick Start

1. **Open the project in Xcode:**
   ```bash
   open WandbApp.xcodeproj
   ```

2. **Get your wandb API key:**
   - Visit https://wandb.ai/settings
   - Navigate to the API keys section
   - Copy your API key

3. **Build and Run:**
   - Select a simulator or connected device
   - Press `Cmd + R` to build and run
   - Or click the Play button in Xcode

4. **Login:**
   - Enter your wandb entity (username or team name)
   - Enter your API key
   - Tap "Sign In"

## Project Structure

```
WandbApp/
├── WandbAppApp.swift          # App entry point
├── ContentView.swift           # Root navigation view
├── Models/                     # Data models
│   ├── AuthenticationManager.swift
│   ├── KeychainHelper.swift
│   └── WandbModels.swift
├── Services/                   # API services
│   └── WandbAPIService.swift
├── Views/                      # SwiftUI views
│   ├── LoginView.swift
│   ├── MainTabView.swift
│   ├── ProjectsView.swift
│   ├── RunsView.swift
│   ├── MetricsView.swift
│   └── SettingsView.swift
└── ViewModels/                 # View models
    ├── ProjectsViewModel.swift
    ├── RunsViewModel.swift
    └── MetricsViewModel.swift
```

## Requirements

- **iOS 16.0+** (for Swift Charts support)
- **Xcode 14.0+**
- **Swift 5.9+**
- Active wandb account

## Features

✅ Secure API key storage (Keychain)  
✅ Project browsing  
✅ Run listing with status  
✅ Interactive training metrics graphs  
✅ Pull-to-refresh  
✅ Auto-login on app restart  

## Troubleshooting

### Build Errors

If you encounter build errors:
1. Clean build folder: `Cmd + Shift + K`
2. Delete DerivedData
3. Restart Xcode

### API Errors

- Verify your API key is correct
- Check your internet connection
- Ensure your entity name matches your wandb username/team

### Charts Not Showing

- Ensure you're running on iOS 16.0+
- Check that the run has logged metrics
- Try pulling to refresh

## Next Steps

- Customize the app icon
- Add more chart types
- Implement run comparison
- Add filtering and search
