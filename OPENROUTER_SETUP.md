# OpenRouter API Configuration

To enable full AI-powered responses, you need to configure an OpenRouter API key.

## Getting an API Key

1. Visit [OpenRouter.ai](https://openrouter.ai/)
2. Sign up for an account
3. Navigate to the API Keys section
4. Create a new API key

## Configuration Options

### Option 1: Rails Credentials (Recommended for Production)

```bash
cd backend
EDITOR="nano" bin/rails credentials:edit
```

Add the following to your credentials file:
```yaml
openrouter_api_key: your_actual_api_key_here
```

### Option 2: Environment Variable (Good for Development)

```bash
export OPENROUTER_API_KEY=your_actual_api_key_here
```

Or add to your `.env` file in the backend directory:
```
OPENROUTER_API_KEY=your_actual_api_key_here
```

## Fallback Behavior

If no API key is configured, the system will:
- Still search for products based on user queries
- Provide helpful fallback responses with product recommendations
- Show informative messages about product selection criteria
- Display found products with prices and ratings

## Testing the Configuration

After adding your API key:

1. Restart the Rails server
2. Send a chat message through the frontend
3. The response should be more detailed and personalized

Example test message: "I need a laptop for programming work with good performance"

## Supported Models

The current configuration uses:
- **Model**: `meta-llama/llama-3.1-8b-instruct:free`
- **Max Tokens**: 1000
- **Temperature**: 0.7

You can modify these settings in `app/services/openrouter_service.rb`.