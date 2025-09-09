# Product Purchase Assistant 🛍️

An advanced AI-powered chatbot that helps users find and compare products from Digikala.com with real-time scraping. Built with Rails 8.0 API backend and Nuxt.js frontend with comprehensive Persian language support.

![Product Purchase Assistant Screenshot](https://github.com/user-attachments/assets/51ed94a5-9390-4ae5-8d69-f34d5a4ed267)

## Features

- 🤖 **AI-Powered Conversations**: Interactive chatbot that understands complex product queries in Persian and English
- 🔍 **Real-Time Product Search**: Live scraping from Digikala with browser automation (Selenium WebDriver)
- 💰 **Comprehensive Product Info**: Real prices, ratings, images, and direct product links
- 📱 **Responsive Persian UI**: RTL support with Vazirmatn font and optimized Persian typography
- ⚡ **Smart Quick Actions**: Pre-defined buttons for common product categories
- 🌐 **Bilingual Support**: Full Persian (Farsi) and English support with intelligent keyword extraction
- 🧠 **Advanced Keyword Extraction**: Recognizes brands, product types, and Persian product terminology
- 🛒 **Direct Product Access**: Real product URLs leading directly to Digikala product pages
- 🔧 **Robust Error Handling**: Multiple fallback strategies for reliable product discovery

## Tech Stack

### Backend (Rails 8.0 API)
- **Ruby**: 3.2+
- **Rails**: 8.0
- **Database**: SQLite3
- **Web Scraping**: Selenium WebDriver 4.1.0 with Firefox/Chrome support
- **HTML Parsing**: Nokogiri for product data extraction
- **AI Integration**: OpenRouter API with intelligent fallbacks
- **Browser Automation**: Multi-strategy scraping with error recovery

### Frontend (Nuxt.js)
- **Node.js**: 20+
- **Nuxt.js**: 4.1+ (Vue 3 Composition API)
- **Styling**: Tailwind CSS with Persian font integration
- **Typography**: Vazirmatn and IRANSans Persian fonts
- **Layout**: RTL support with Persian-optimized UI components

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

4. **Install Browser Dependencies** (for real-time scraping):
   ```bash
   # For Firefox (recommended):
   sudo apt-get update
   sudo apt-get install firefox-esr
   
   # Or for Chromium:
   sudo apt-get install chromium-browser
   
   # Install Selenium WebDriver dependencies:
   bundle exec rails runner "DigikalaScrapingService.test_browser_availability"
   ```

5. **Configure OpenRouter API (Optional)**:
   ```bash
   # Add to config/credentials.yml.enc
   rails credentials:edit
   
   # Add:
   openrouter_api_key: your_api_key_here
   
   # Or set environment variable:
   export OPENROUTER_API_KEY=your_api_key_here
   ```

6. **Start the server**:
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
  - Body: `{ "message": "لپ تاپ گیمینگ میخوام" }` or `{ "message": "I need a laptop for work" }`
  - Response: AI response with real-time product recommendations from Digikala
  - Features: Intelligent Persian/English keyword extraction, brand recognition

### Products
- **GET** `/api/v1/products/search?q=gaming laptop`
  - Response: Live scraped products from Digikala with real prices and URLs
  - Supports: Persian queries (`ماشین اصلاح صورت`), English terms, brand names

## Configuration

### Backend Configuration

#### OpenRouter AI Service
The backend uses intelligent fallbacks for AI responses. To enable full AI capabilities:

1. Get an API key from [OpenRouter](https://openrouter.ai/)
2. Add it to Rails credentials or environment variables
3. Restart the Rails server

#### Browser Configuration for Scraping
The system automatically detects available browsers (Firefox preferred, Chrome fallback):

```ruby
# Test browser availability
bundle exec rails runner "DigikalaScrapingService.test_browser_availability"

# Manual browser selection (if needed)
# Set environment variable:
export BROWSER_TYPE=firefox  # or 'chrome'
```

#### Supported Product Categories
The system recognizes Persian keywords for:
- Electronics: `موبایل`, `لپ تاپ`, `هدفون`, `ساعت هوشمند`
- Personal Care: `ماشین اصلاح صورت`, `شامپو`, `کرم`, `عطر`
- Home & Kitchen: `یخچال`, `ماشین لباسشویی`, `مایکروویو`
- Fashion & Beauty: `کفش`, `لباس`, `کیف`, `آرایش`
- Sports & Outdoor: `دوچرخه`, `کفش ورزشی`, `ساک ورزشی`

### Frontend Configuration

The frontend is configured for Persian language support with:

#### Persian Typography & Fonts
```javascript
// nuxt.config.ts includes:
app: {
  head: {
    link: [
      // Vazirmatn Persian font family
      { rel: 'preconnect', href: 'https://fonts.googleapis.com' },
      { rel: 'stylesheet', href: 'https://fonts.googleapis.com/css2?family=Vazirmatn:wght@300;400;500;700&display=swap' },
      // IRANSans fallback font
      { rel: 'stylesheet', href: 'https://cdn.fontcdn.ir/Font/Persian/IRANSans/IRANSans.css' }
    ]
  }
}
```

#### API Configuration
```javascript
runtimeConfig: {
  public: {
    apiBase: 'http://localhost:3001/api/v1'
  }
}
```

#### Persian Font Classes
The application uses custom `font-persian` classes for optimal Persian text rendering:
- Headers: Vazirmatn font with proper weight
- Body text: IRANSans fallback support
- RTL layout: Automatic Persian text direction

## Usage

### Basic Chat (Persian & English)
1. Type your product query in Persian or English:
   - Persian: `لپ تاپ گیمینگ زیر ۳۰ میلیون تومان`
   - English: `Gaming laptop under 30 million tomans`
2. The AI analyzes your request and scrapes real-time data from Digikala
3. Review live product recommendations with real prices and images
4. Click "مشاهده محصول" (View Product) to visit the actual Digikala product page

### Quick Actions (دسترسی سریع)
Use predefined buttons for common Persian searches:
- 💻 **یافتن لپ تاپ**: Browse laptops for work and gaming
- 📱 **یافتن گوشی**: Latest smartphones and accessories  
- 🎧 **یافتن هدفون**: Audio equipment and accessories

### Example Queries (نمونه جستجوها)
#### Persian Examples:
- `ماشین اصلاح صورت خوب میخوام`
- `لپ تاپ گیمینگ ارزان قیمت`
- `بهترین گوشی زیر ۲۰ میلیون`
- `هدفون بی سیم برای ورزش`

#### English Examples:
- "I need a laptop for work under 30 million tomans"
- "Show me the best smartphones with good cameras"
- "Compare gaming headphones"
- "What's the best value laptop?"

### Smart Product Recognition
The system intelligently recognizes:
- **Brands**: Samsung, Apple, ASUS, HP, Sony, etc.
- **Categories**: Electronics, personal care, home appliances
- **Persian Terms**: Comprehensive database of Persian product terminology
- **Mixed Queries**: Persian + English in the same message

## Architecture

### Service Layer
- **OpenrouterService**: Handles AI API communication with intelligent fallback responses
- **DigikalaScrapingService**: Real-time browser automation for live product data
  - Selenium WebDriver integration with Firefox/Chrome support
  - Smart URL extraction with parent element traversal
  - Robust error handling and retry mechanisms
  - Product data normalization and Persian text processing

### Controllers
- **ChatbotController**: 
  - Processes bilingual chat messages (Persian/English)
  - Advanced keyword extraction for 50+ product categories
  - Intelligent product search triggering
  - Persian language response formatting
- **ProductsController**: Handles direct product search with real-time scraping

### Frontend Components
- **Chat Interface**: 
  - RTL support for Persian conversations
  - Real-time messaging with Persian typography
  - Loading states with Persian indicators
- **Product Cards**: 
  - Persian/English bilingual product information
  - Real Digikala prices and ratings
  - Direct product page navigation
- **Quick Actions**: 
  - Persian category-based search shortcuts
  - Culturally relevant product suggestions

### Data Flow
1. **User Input**: Persian/English query processed by frontend
2. **Keyword Analysis**: Backend extracts product intent and categories  
3. **Real-time Scraping**: Selenium automation searches Digikala
4. **Data Processing**: Product information parsed and normalized
5. **AI Enhancement**: OpenRouter generates contextual responses
6. **Persian Rendering**: Frontend displays with proper RTL and fonts

## Development

### Running Tests
```bash
# Backend tests
cd backend
bin/rails test

# Test browser scraping functionality
bin/rails runner "DigikalaScrapingService.test_browser_availability"

# Test Persian keyword detection
bin/rails runner "puts ChatbotController.new.send(:should_search_products?, 'ماشین اصلاح صورت')"

# Frontend tests (if implemented)
cd frontend
npm run test
```

### Code Style
- **Backend**: Follow Rails conventions with RuboCop
- **Frontend**: Vue 3 Composition API with TypeScript
- **Persian Text**: Proper RTL handling and font rendering
- **Browser Automation**: Error handling and graceful fallbacks

### Development Tips
1. **Browser Setup**: Ensure Firefox or Chrome is installed for scraping
2. **Persian Testing**: Test with various Persian product terms
3. **Font Loading**: Verify Persian fonts load correctly in development
4. **API Integration**: Test both with and without OpenRouter API key

## Deployment

### Backend Deployment
The Rails app is configured with:
- **Docker Support**: Dockerfile included with browser dependencies
- **Kamal Deployment**: Configuration for cloud deployment
- **Thruster**: Production optimization for static assets
- **Environment Variables**: Browser type and API key configuration

### Frontend Deployment
```bash
cd frontend
npm run build
npm run preview

# Verify Persian fonts are properly bundled
npm run analyze  # Check bundle size with Persian fonts
```

### Production Considerations
- **Browser Dependencies**: Ensure headless browser availability
- **Font Optimization**: Persian fonts should be preloaded for performance
- **API Rate Limits**: Consider caching for Digikala scraping
- **Error Monitoring**: Track scraping failures and fallbacks

## Contributing

We welcome contributions! Please feel free to:

1. **Report Issues**: Bug reports, feature requests, or Persian UI improvements
2. **Submit PRs**: Code improvements, additional product categories, or browser compatibility
3. **Enhance Translations**: Improve Persian language support and terminology
4. **Optimize Scraping**: Better selectors, error handling, or performance improvements

### Development Guidelines
- Test both Persian and English functionality
- Ensure browser automation works across different environments  
- Maintain RTL compatibility for Persian UI elements
- Follow existing code patterns for consistency

## License

This project is open source and available under the [MIT License](LICENSE).

## Support

For questions, issues, or feature requests, please:
- Open an issue on GitHub
- Check existing documentation
- Test with different Persian product terms
- Verify browser dependencies are correctly installed

---

Built with ❤️ for the Persian-speaking community | ساخته شده با ❤️ برای جامعه فارسی زبان

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