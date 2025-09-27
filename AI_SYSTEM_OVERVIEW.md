# AI-Powered Product Search System - Technical Overview

## System Architecture

The Product Purchase Assistant uses a sophisticated multi-layered AI approach to search and recommend products from Digikala.com. This document explains how the AI agent generates intelligent prompts and optimizes product searches.

## Core AI Components

### 1. Enhanced Prompt Service (`EnhancedPromptService`)

**Purpose**: Creates contextually-aware, sophisticated prompts for better AI responses.

**Key Features**:
- **Search Optimization**: Generates optimized search terms using AI analysis
- **Context Analysis**: Analyzes user intent, language, budget, and technical level
- **Dynamic Prompting**: Creates personalized system prompts based on user context
- **Cultural Awareness**: Persian language optimization and cultural context

#### Search Optimization Example:
```ruby
# User query: "گوشی سامسونگ ارزان برای عکاسی"
# Generated optimized searches:
{
  "primary": "گوشی سامسونگ دوربین",
  "alternative": "گوشی سامسونگ", 
  "fallback": "گوشی دوربین",
  "reasoning": "Combined brand + feature + budget analysis for optimal Digikala search"
}
```

### 2. Intelligent Search Service (`IntelligentSearchService`)

**Purpose**: Orchestrates AI-optimized product searches with ranking and deduplication.

**Search Strategy**:
1. **AI Query Optimization**: Uses LLM to generate multiple search variations
2. **Multi-Strategy Search**: Executes searches with different approaches
3. **Smart Deduplication**: Removes similar products using name similarity
4. **Relevance Ranking**: Scores products based on query match, ratings, and price
5. **Contextual Response**: Generates enhanced AI responses with product context

#### Intelligent Search Flow:
```
User Query → AI Query Optimization → Multi-Search Execution → Deduplication → Relevance Ranking → Enhanced AI Response
```

### 3. Enhanced Chatbot Controller

**Purpose**: Manages conversation flow with intelligent product search integration.

**New Features**:
- **AI Optimization Toggle**: Can switch between standard and AI-optimized search
- **Query Metadata Analysis**: Provides insights into language, intent, and confidence
- **Enhanced Error Handling**: Context-aware error messages in Persian/English
- **Search Metadata**: Tracks search methods and performance metrics

#### API Response Enhancement:
```json
{
  "response": "AI generated response...",
  "products": [...],
  "searched_for": "optimized search term",
  "product_count": 12,
  "search_metadata": {
    "method": "ai_optimized",
    "query_analysis": {
      "language": "persian",
      "intent_confidence": 85.3,
      "contains_brands": ["سامسونگ"],
      "category_predictions": ["electronics"]
    },
    "response_timestamp": "2025-09-27T10:30:00Z"
  }
}
```

### 4. Enhanced OpenRouter Integration

**Purpose**: Improved AI service with better prompting, error handling, and fallbacks.

**Improvements**:
- **Custom Prompt Support**: Accepts enhanced prompts from prompt service
- **Better Error Handling**: Timeout handling and graceful degradation
- **Enhanced Fallbacks**: Context-aware responses when AI is unavailable
- **Product Analysis**: Automatic price, rating, and brand analysis

## AI Prompt Engineering Strategy

### System Prompt Construction

The system builds intelligent prompts that include:

#### 1. **Persona Definition**
```
You are a highly knowledgeable Persian-speaking product consultant specializing in Digikala.com products.
Your expertise includes:
- Deep knowledge of Iranian consumer preferences and market trends
- Understanding of Persian product terminology and brand names
- Awareness of local pricing patterns and value propositions
- Cultural sensitivity to Persian shopping habits and expectations
```

#### 2. **Context Analysis**
```
User Query Analysis:
- Original message: "گوشی سامسونگ ارزان برای عکاسی"
- Language: Persian (Primary) with some English terms
- Intent: specific_search, budget_conscious, feature_focused
- Urgency level: normal
- Technical expertise: general
- Budget sensitivity: budget_conscious
- Usage context: photography
```

#### 3. **Product Context**
```
Available Products from Digikala:

Product 1:
- Name: Samsung Galaxy A54 5G
- Price: ۲۸،۵۰۰،۰۰۰ تومان
- Rating: ۴.۲ از ۵
- Brand: Samsung
- Description: گوشی هوشمند با دوربین ۵۰ مگاپیکسل
- Value Analysis: Good value - high rated
- Target User: Photography enthusiasts and general consumers
```

#### 4. **Instruction Framework**
```
Instructions:
1. Analyze all provided products comprehensively
2. Compare based on: price/value ratio, brand reputation, user ratings, features
3. Provide clear recommendations for different use cases
4. Highlight pros and cons for each significant option
5. Ask follow-up questions to better understand specific needs
6. Include cultural context (e.g., popular brands in Iran, local preferences)
7. Mention any seasonal considerations or current market trends
8. Provide actionable advice for making the final decision

Always respond in fluent, natural Persian with appropriate technical vocabulary.
```

## Search Intelligence Features

### 1. **Multi-Language Keyword Extraction**

The system intelligently processes both Persian and English terms:

```ruby
# Persian brands recognition
persian_brands = ['سامسونگ', 'آیفون', 'اپل', 'هواوی', 'شیائومی']

# English fallbacks
english_brands = ['samsung', 'iphone', 'apple', 'huawei', 'xiaomi']

# Product categories in Persian
persian_products = [
  'گوشی موبایل', 'لپ تاپ', 'هدفون', 'تبلت', 'ساعت هوشمند',
  'ماشین اصلاح صورت', 'یخچال', 'ماشین لباسشویی'
]
```

### 2. **Intelligent Query Optimization**

For AI-optimized searches, the system:
1. Analyzes user intent and context
2. Generates multiple search strategies
3. Combines brands, categories, and features optimally
4. Provides fallback options for better coverage

### 3. **Product Relevance Scoring**

Products are scored based on:
- **Name Match** (10 points per matching word)
- **Brand Match** (20 points for brand alignment)
- **Price Availability** (5 points for valid pricing)
- **Rating Quality** (2 points per rating star)
- **Search Strategy** (15-5 points based on search specificity)

### 4. **Smart Deduplication**

Removes similar products using:
- URL comparison (exact duplicates)
- Name similarity analysis (70% word overlap threshold)
- Normalized text comparison (removing noise words)

## Real-World Usage Examples

### Example 1: Persian Budget Smartphone Search
**User Query**: `"گوشی ارزان زیر ۲۰ میلیون تومان میخوام"`

**AI Processing**:
1. **Intent Detection**: budget_search + smartphone
2. **Keyword Extraction**: "گوشی" + budget constraints
3. **Search Optimization**: 
   - Primary: "گوشی ارزان قیمت"
   - Alternative: "گوشی بودجه"
   - Fallback: "گوشی"
4. **Context Analysis**: Persian, budget-conscious, general user
5. **AI Response**: Personalized recommendations with price comparisons

### Example 2: Technical Gaming Laptop Search
**User Query**: `"لپ تاپ گیمینگ با RTX 4060 برای بازی"`

**AI Processing**:
1. **Intent Detection**: specific_feature + gaming + technical
2. **Keyword Extraction**: "لپ تاپ گیمینگ" + "RTX 4060"
3. **Technical Level**: Advanced (mentions specific GPU)
4. **AI Response**: Detailed technical comparisons, gaming performance analysis

### Example 3: Mixed Language Brand Search
**User Query**: `"Samsung Galaxy A54 یا iPhone 13 کدوم بهتره؟"`

**AI Processing**:
1. **Language Detection**: Mixed Persian/English
2. **Intent Detection**: Comparison + specific products
3. **Brand Extraction**: Samsung, iPhone
4. **AI Response**: Head-to-head comparison with Persian explanations

## API Integration Points

### Standard Search (Original)
```bash
POST /api/v1/chatbot/chat
{
  "message": "گوشی سامسونگ میخوام",
  "ai_optimization": false
}
```

### AI-Optimized Search (Enhanced)
```bash
POST /api/v1/chatbot/chat
{
  "message": "گوشی سامسونگ میخوام",
  "ai_optimization": true  # Default: true
}
```

### Direct Product Search
```bash
GET /api/v1/products/search?q=samsung%20galaxy&limit=10
```

## Performance Optimizations

### 1. **Caching Strategy**
- Cache AI-generated search optimizations
- Store frequently requested product data
- Cache brand and category mappings

### 2. **Fallback Mechanisms**
- Rule-based search when AI is unavailable
- Progressive degradation of features
- Local Persian language processing

### 3. **Search Efficiency**
- Limit concurrent browser sessions
- Implement request queuing for heavy loads
- Smart timeout handling for scraping operations

## Configuration Options

### Environment Variables
```bash
# AI Service Configuration
OPENROUTER_API_KEY=your_api_key_here
AI_OPTIMIZATION_ENABLED=true
AI_TIMEOUT_SECONDS=30

# Search Configuration  
MAX_PRODUCTS_PER_SEARCH=15
SEARCH_TIMEOUT_SECONDS=45
BROWSER_TYPE=firefox  # or chrome

# Language and Cultural Settings
DEFAULT_LANGUAGE=persian
CULTURAL_CONTEXT=iran
CURRENCY_DISPLAY=تومان
```

### Runtime Configuration
```ruby
# config/application.rb
config.ai_search = {
  enabled: true,
  fallback_to_standard: true,
  max_search_terms: 3,
  relevance_threshold: 10.0,
  similarity_threshold: 0.7
}
```

## Future Enhancements

### 1. **Advanced AI Features**
- **Conversation Memory**: Remember user preferences across sessions
- **Learning System**: Improve search based on user feedback
- **Predictive Search**: Suggest products before user asks

### 2. **Enhanced Search Intelligence**
- **Visual Search**: Image-based product finding
- **Voice Search**: Persian voice command support
- **Contextual Awareness**: Consider season, trends, user history

### 3. **Performance Improvements**
- **ML-based Ranking**: Train models on user interaction data  
- **Real-time Price Tracking**: Monitor price changes
- **Inventory Awareness**: Check product availability

### 4. **Cultural and Language Enhancements**
- **Dialect Support**: Handle different Persian dialects
- **Regional Preferences**: Customize for different Iranian regions
- **Cultural Events**: Adjust recommendations for Persian holidays

## Development Guidelines

### Adding New Product Categories
```ruby
# Add to intelligent_search_service.rb
def extract_categories(query)
  persian_categories = {
    'نام دسته جدید' => ['کلیدواژه۱', 'کلیدواژه۲', 'english_keyword'],
    # ...
  }
end
```

### Enhancing AI Prompts
```ruby
# Add to enhanced_prompt_service.rb  
def build_specialized_prompt(domain)
  case domain
  when :electronics
    # Specialized electronics prompting
  when :fashion  
    # Specialized fashion prompting
  end
end
```

### Performance Monitoring
```ruby
# Add instrumentation
def search_with_ai_optimization(query, limit)
  start_time = Time.current
  result = perform_search(query, limit)
  
  Rails.logger.info "AI search completed in #{Time.current - start_time}s"
  result
end
```

This AI-powered system provides a comprehensive, culturally-aware, and technically sophisticated approach to product search and recommendation, specifically optimized for Persian-speaking users and the Iranian market context.