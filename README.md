# Product Purchase Assistant 🛍️

An AI-powered chatbot that helps users find and compare products from Digikala.com. Built with Rails 8.0 API backend and Nuxt.js frontend.

![Product Purchase Assistant Screenshot](https://github.com/user-attachments/assets/51ed94a5-9390-4ae5-8d69-f34d5a4ed267)

## Features

- 🤖 **AI-Powered Conversations**: Interactive chatbot that understands product queries
- 🔍 **Product Search**: Automatically searches Digikala for relevant products
- 💰 **Price Comparison**: Shows prices, ratings, and brand information
- 📱 **Responsive Design**: Works on desktop and mobile devices
- ⚡ **Quick Actions**: Pre-defined buttons for common product categories
- 🌐 **Bilingual Support**: Supports both English and Persian (Farsi)

## Tech Stack

### Backend (Rails 8.0 API)
- **Ruby**: 3.2+
- **Rails**: 8.0
- **Database**: SQLite3
- **HTTP Client**: HTTParty for API requests
- **Web Scraping**: Nokogiri for HTML parsing
- **AI Integration**: OpenRouter API (configurable)

### Frontend (Nuxt.js)
- **Node.js**: 20+
- **Nuxt.js**: 4.1+ (Vue 3)
- **Styling**: Tailwind CSS
- **API Communication**: Built-in $fetch

## Installation & Setup

### Prerequisites
- Ruby 3.2+
- Node.js 20+
- Git

### Backend Setup

1. **Navigate to backend directory**:
   ```bash
   cd backend
   ```

2. **Install dependencies**:
   ```bash
   bundle install
   ```

3. **Setup database**:
   ```bash
   bin/rails db:create
   ```

4. **Configure OpenRouter API (Optional)**:
   ```bash
   # Add to config/credentials.yml.enc
   rails credentials:edit
   
   # Add:
   openrouter_api_key: your_api_key_here
   
   # Or set environment variable:
   export OPENROUTER_API_KEY=your_api_key_here
   ```

5. **Start the server**:
   ```bash
   bin/rails server -p 3001
   ```

### Frontend Setup

1. **Navigate to frontend directory**:
   ```bash
   cd frontend
   ```

2. **Install dependencies**:
   ```bash
   npm install
   ```

3. **Start development server**:
   ```bash
   npm run dev
   ```

4. **Visit the application**:
   Open [http://localhost:3000](http://localhost:3000) in your browser

## API Endpoints

### Chatbot
- **POST** `/api/v1/chatbot/chat`
  - Body: `{ "message": "I need a laptop for work" }`
  - Response: AI response with product recommendations

### Products
- **GET** `/api/v1/products/search?q=laptop`
  - Response: List of products matching the query

## Configuration

### Backend Configuration

The backend automatically falls back to helpful responses when OpenRouter API key is not configured. To enable full AI capabilities:

1. Get an API key from [OpenRouter](https://openrouter.ai/)
2. Add it to Rails credentials or environment variables
3. Restart the Rails server

### Frontend Configuration

Update `nuxt.config.ts` to change the API base URL if needed:

```typescript
runtimeConfig: {
  public: {
    apiBase: 'http://localhost:3001/api/v1'
  }
}
```

## Usage

### Basic Chat
1. Type your product query in the chat input
2. The AI will analyze your request and search for relevant products
3. Review the recommendations and click "View Product" to visit Digikala

### Quick Actions
Use the predefined buttons for common searches:
- 💻 **Find Laptops**: Browse laptops for work and gaming
- 📱 **Find Smartphones**: Latest mobile phones and accessories  
- 🎧 **Find Headphones**: Audio equipment and accessories

### Example Queries
- "I need a laptop for work under 30 million tomans"
- "Show me the best smartphones with good cameras"
- "Compare headphones for gaming"
- "What's the best value laptop?"

## Architecture

### Service Layer
- **OpenrouterService**: Handles AI API communication with fallback responses
- **DigikalaScrapingService**: Manages product data retrieval (currently using mock data)

### Controllers
- **ChatbotController**: Processes chat messages and coordinates AI responses
- **ProductsController**: Handles direct product search requests

### Frontend Components
- **Chat Interface**: Real-time messaging with typing indicators
- **Product Cards**: Rich product information display
- **Quick Actions**: Category-based search shortcuts

## Development

### Running Tests
```bash
# Backend tests
cd backend
bin/rails test

# Frontend tests (if implemented)
cd frontend
npm run test
```

### Code Style
- Backend: Follow Rails conventions with RuboCop
- Frontend: Vue 3 Composition API with TypeScript

## Deployment

### Backend Deployment
The Rails app is configured with:
- Docker support (Dockerfile included)
- Kamal deployment configuration
- Thruster for production optimization

### Frontend Deployment
```bash
cd frontend
npm run build
npm run preview
```

## Contributing

1. Fork the repository
2. Create a feature branch: `git checkout -b feature/new-feature`
3. Commit changes: `git commit -m 'Add new feature'`
4. Push to branch: `git push origin feature/new-feature`
5. Submit a Pull Request

## Environment Variables

| Variable | Description | Required |
|----------|-------------|----------|
| `OPENROUTER_API_KEY` | OpenRouter API key for AI responses | Optional |
| `RAILS_ENV` | Rails environment (development/production) | No |

## Known Limitations

1. **Web Scraping**: Currently uses mock data for Digikala products due to anti-bot measures
2. **AI Responses**: Limited functionality without OpenRouter API key
3. **Product Images**: Using placeholder URLs in mock data

## Future Enhancements

- [ ] Real Digikala integration with proper API or advanced scraping
- [ ] User authentication and purchase history
- [ ] Product comparison features
- [ ] Price tracking and alerts
- [ ] Multiple language support
- [ ] Advanced filtering and sorting
- [ ] Product reviews integration

## License

This project is open source and available under the [MIT License](LICENSE).

## Support

For support, please open an issue in the GitHub repository or contact the development team.

---

**Built with ❤️ for better online shopping experiences**