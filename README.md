# Incash - Dividend Tracker

A SwiftUI iOS app to track and manage dividend income from your stock portfolio.

## Features

- **Automated Dividend Tracking**: Fetches dividend information from Gmail using Google OAuth
- **Manual Entry**: Add, edit, and delete dividend entries manually
- **Portfolio Visualization**: View dividend allocation with interactive pie charts
- **Dual Data Sources**: Separate tracking for API-fetched and manually entered dividends
- **AI-Powered Extraction**: Uses Gemini AI to extract dividend details from emails
- **Core Data Persistence**: Local storage with composite primary keys (ticker + dataSourceType)

## Tech Stack

- **SwiftUI** - UI framework
- **Core Data** - Local database
- **Google OAuth** - Authentication
- **Gmail API** - Email fetching
- **Gemini API** - AI-powered data extraction

## Setup

1. Clone the repository
2. Create `Config.xcconfig` in the project root:
   ```
   GEMINI_API_KEY = your_gemini_api_key
   GID_CLIENT_ID = your_firebase_project_key
   ```
3. Add `GoogleService-Info.plist` for Google OAuth configuration and ```GID_CLIENT_ID```
4. Configure `Info.plist` with:
   - `CFBundleDisplayName = Incash`
   - 
   ```
   GEMINI_API_KEY = $(GEMINI_API_KEY)
   GID_CLIENT_ID = $(GID_CLIENT_ID)
   ```
   - Google OAuth URL schemes
   - Required API permissions

## Architecture

- **MVVM Pattern**: Separation of UI and business logic
- **Singleton Pattern**: DividendDBHelper for database operations
- **ObservableObject**: MainViewModel for state management

## Key Components

- `MainViewModel`: Handles data fetching, processing, and CRUD operations
- `DividendDBHelper`: Core Data operations with NSManagedObject
- `LoginViewModel`: Google OAuth authentication flow
- `GeminiService`: AI-powered dividend extraction from emails
- `GmailAPIService`: Gmail API integration

## Color Scheme

- Primary: Pink (#FFB1E1)
- Accent: Deep Pink (#ab0c6e)
- Background: Black (#000000)
- Cards: Dark Gray (#121212)

## DB Data Model

```swift
DividendRecord {
    ticker: String
    companyName: String
    netDividend: Double
    dataSourceType: String // "remote" or "manual"
    createdAt: Date
}
```

## License

Private project
