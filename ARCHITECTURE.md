# Product Purchase Assistant - Architecture Documentation

## Overview

The Product Purchase Assistant is an AI-powered chatbot application that helps users find and compare products from Digikala.com. The system consists of a Rails 8.0 API backend and a Nuxt.js frontend, designed with a modular, scalable architecture.

## System Architecture

```
┌─────────────────────────────────────────────────────────────────┐
│                    Frontend (Nuxt.js 4.1+)                     │
│  ┌─────────────────┐  ┌─────────────────┐  ┌─────────────────┐ │
│  │   Chat UI       │  │  Quick Actions  │  │  Product Cards  │ │
│  │                 │  │                 │  │                 │ │
│  │ - Messages      │  │ - Category      │  │ - Price         │ │
│  │ - Input Field   │  │   Buttons       │  │ - Rating        │ │
│  │ - Typing        │  │ - Pre-defined   │  │ - Brand         │ │
│  │   Indicator     │  │   Queries       │  │ - Description   │ │
│  └─────────────────┘  └─────────────────┘  └─────────────────┘ │
└─────────────────────────────────────────────────────────────────┘
                                │
                        HTTP API Calls
                                │
┌─────────────────────────────────────────────────────────────────┐
│                    Backend (Rails 8.0 API)                     │
│  ┌─────────────────┐  ┌─────────────────┐  ┌─────────────────┐ │
│  │   Controllers   │  │    Services     │  │    External     │ │
│  │                 │  │                 │  │     APIs        │ │
│  │ - Chatbot       │  │ - OpenRouter    │  │ - OpenRouter    │ │
│  │   Controller    │  │   Service       │  │   AI API        │ │
│  │ - Products      │  │ - Digikala      │  │ - Digikala      │ │
│  │   Controller    │  │   Scraping      │  │   Website       │ │
│  └─────────────────┘  └─────────────────┘  └─────────────────┘ │
└─────────────────────────────────────────────────────────────────┘
```

## Technology Stack

### Backend Stack
- **Ruby**: 3.2+
- **Rails**: 8.0 (API mode)
- **Database**: SQLite3 (development), configurable for production
- **Web Server**: Puma
- **HTTP Client**: HTTParty for external API requests
- **HTML Parser**: Nokogiri for web scraping
- **Deployment**: Docker + Kamal support
- **Optimization**: Thruster for production performance
- **CORS**: Rack-CORS for cross-origin requests

### Frontend Stack
- **Node.js**: 20+
- **Nuxt.js**: 4.1+ (Vue 3 Composition API)
- **Styling**: Tailwind CSS with custom design system
- **Build Tool**: Vite (included with Nuxt)
- **TypeScript**: Full TypeScript support
- **API Client**: Built-in $fetch utility

### External Services
- **AI Provider**: OpenRouter API (meta-llama/llama-3.1-8b-instruct:free)
- **Product Data**: Digikala.com (currently using mock data)

## Backend Architecture

### Directory Structure
```
backend/
├── app/
│   ├── controllers/
│   │   ├── application_controller.rb
│   │   └── api/v1/
│   │       ├── chatbot_controller.rb      # Chat message handling
│   │       └── products_controller.rb     # Direct product search
│   ├── services/
│   │   ├── openrouter_service.rb         # AI API integration
│   │   └── digikala_scraping_service.rb  # Product data retrieval
│   └── models/                           # (Currently minimal)
├── config/
│   ├── routes.rb                        # API routing
│   ├── application.rb                   # Rails configuration
│   └── initializers/cors.rb            # CORS settings
└── db/                                  # Database schema and seeds
```

### API Endpoints

#### Chatbot API
- **Endpoint**: `POST /api/v1/chatbot/chat`
- **Purpose**: Main conversational interface
- **Request**: `{ "message": "I need a laptop for work", "product_query": "laptop" }`
- **Response**: 
  ```json
  {
    "response": "AI generated response...",
    "products": [...],
    "searched_for": "laptop"
  }
  ```

#### Products API
- **Endpoint**: `GET /api/v1/products/search?q=laptop&limit=10`
- **Purpose**: Direct product search
- **Response**:
  ```json
  {
    "query": "laptop",
    "products": [...],
    "count": 5
  }
  ```

### Service Layer Architecture

#### OpenrouterService
**Purpose**: AI conversation management with graceful fallback

**Key Features**:
- API key validation and fallback responses
- Intelligent system prompt construction
- Context-aware product recommendations
- Error handling and logging

**Methods**:
- `chat_completion(message, context)` - Main AI interaction
- `generate_fallback_response(message, context)` - Non-AI fallback
- `build_system_prompt(context)` - Dynamic prompt generation

#### DigikalaScrapingService
**Purpose**: Product data retrieval (currently mock implementation)

**Key Features**:
- Query-based product search
- Category-specific mock data
- Extensible for real scraping implementation
- Error handling and graceful degradation

**Methods**:
- `search_products(query, limit)` - Main search interface
- `generate_mock_products(query, limit)` - Mock data generation
- `parse_search_results(html, limit)` - Future real implementation

### Controller Layer

#### ChatbotController
**Responsibilities**:
- Message validation and processing
- Product query detection and extraction
- Service coordination (AI + Product search)
- Response formatting
- Error handling

**Key Methods**:
- `chat` - Main chat endpoint
- `should_search_products?` - Intent detection
- `extract_product_keywords` - Query extraction

#### ProductsController
**Responsibilities**:
- Direct product search handling
- Query validation
- Response formatting

## Frontend Architecture

### Component Structure
```
frontend/
├── app/
│   └── app.vue                    # Main application component
├── pages/
│   └── index.vue                  # Home page (SPA routing)
├── assets/css/
│   └── main.css                   # Global styles and Tailwind
└── public/                        # Static assets
```

### Main Component (app.vue)

**State Management**:
- `messages[]` - Chat conversation history
- `userMessage` - Current input
- `isTyping` - Loading state indicator

**Key Features**:
- Real-time chat interface
- Product card display
- Quick action buttons
- Responsive design
- Accessibility support

**Methods**:
- `sendMessage()` - API communication
- `quickSearch()` - Predefined category searches
- `formatMessage()` - Content rendering
- `scrollToBottom()` - UX enhancement

### Configuration

#### Runtime Configuration
```typescript
runtimeConfig: {
  public: {
    apiBase: 'http://localhost:3001/api/v1'
  }
}
```

#### Tailwind CSS Integration
- Custom color scheme
- Responsive breakpoints
- Component-specific styles
- Animation utilities

## Data Flow

### Chat Message Flow
1. **User Input**: User types message in frontend
2. **Frontend Processing**: Message validation and UI updates
3. **API Request**: POST to `/api/v1/chatbot/chat`
4. **Backend Processing**:
   - Message analysis for product intent
   - Product search (if relevant)
   - AI prompt construction
   - OpenRouter API call (or fallback)
5. **Response Assembly**: Combine AI response with product data
6. **Frontend Rendering**: Display message and product cards

### Product Search Flow
1. **Query Extraction**: From chat message or direct search
2. **Service Call**: DigikalaScrapingService.search_products()
3. **Data Processing**: Parse/generate product information
4. **Context Assembly**: Format for AI system prompt
5. **Response Integration**: Include in chat response

## Security Considerations

### API Security
- **CORS Configuration**: Restricted to localhost in development
- **Input Validation**: Message and query parameter validation
- **Error Handling**: Graceful degradation without data exposure
- **Rate Limiting**: Not implemented (future enhancement)

### Data Privacy
- **No Persistent Storage**: Chat messages not stored
- **API Key Management**: Rails credentials or environment variables
- **External API Calls**: Only to trusted services (OpenRouter, Digikala)

## Deployment Architecture

### Development Environment
- **Backend**: Rails server on port 3001
- **Frontend**: Nuxt dev server on port 3000
- **Database**: SQLite3 local files

### Production Considerations
- **Docker Support**: Dockerfile included for containerization
- **Kamal Deployment**: Ready for modern deployment workflows
- **Thruster Optimization**: Asset compression and caching
- **Database**: Configurable for PostgreSQL/MySQL
- **Environment Variables**: Production-ready configuration

## Scalability Considerations

### Current Limitations
1. **Single Server**: No horizontal scaling
2. **SQLite Database**: Not suitable for high concurrency
3. **Mock Data**: Limited product information
4. **No Caching**: Each request hits external APIs

### Future Scalability Solutions
1. **Database Migration**: PostgreSQL with connection pooling
2. **Caching Layer**: Redis for API responses and product data
3. **Background Jobs**: Async product data updates
4. **CDN Integration**: Static asset optimization
5. **Load Balancing**: Multiple Rails instances

## Monitoring and Logging

### Current Implementation
- **Rails Logging**: Standard Rails.logger usage
- **Error Handling**: Try-catch blocks with logging
- **API Response Tracking**: Success/failure logging

### Recommended Enhancements
- **APM Integration**: Application performance monitoring
- **Health Checks**: `/up` endpoint for monitoring
- **Metrics Collection**: API response times and success rates
- **Error Tracking**: Centralized error reporting

## Development Guidelines

### Code Organization Principles
1. **Service Layer Pattern**: Business logic in services
2. **Controller Simplicity**: Thin controllers, fat services
3. **Error Handling**: Consistent error responses
4. **Separation of Concerns**: Clear responsibility boundaries

### API Design Principles
1. **RESTful Routes**: Following Rails conventions
2. **Consistent Response Format**: Standardized JSON structure
3. **Versioning**: `/api/v1/` namespace for future compatibility
4. **Documentation**: Self-documenting through consistent patterns

### Frontend Patterns
1. **Composition API**: Vue 3 modern patterns
2. **Reactive Data**: Ref and reactive state management
3. **Component Reusability**: Modular design approach
4. **Performance**: Minimal bundle size and fast rendering

## Future Development Roadmap

### Phase 1: Core Improvements
- [ ] Real Digikala integration
- [ ] Enhanced AI prompting
- [ ] User session management
- [ ] Product comparison features

### Phase 2: Advanced Features
- [ ] User authentication
- [ ] Purchase history
- [ ] Price tracking alerts
- [ ] Multi-language support

### Phase 3: Scale and Performance
- [ ] Database optimization
- [ ] Caching implementation
- [ ] Background job processing
- [ ] Performance monitoring

### Phase 4: Enterprise Features
- [ ] Admin dashboard
- [ ] Analytics and reporting
- [ ] A/B testing framework
- [ ] Advanced recommendation engine

## Contributing Guidelines

### Development Setup
1. Clone repository
2. Setup backend (Ruby/Rails)
3. Setup frontend (Node.js/Nuxt)
4. Configure environment variables
5. Run tests and verify functionality

### Code Standards
- **Backend**: RuboCop Rails Omakase configuration
- **Frontend**: ESLint with Vue/Nuxt recommendations
- **Git**: Conventional commit messages
- **Testing**: Comprehensive test coverage

### Pull Request Process
1. Feature branch from main
2. Implement changes with tests
3. Update documentation
4. Submit PR with description
5. Code review and merge

This architecture documentation provides a foundation for understanding, maintaining, and extending the Product Purchase Assistant application.
