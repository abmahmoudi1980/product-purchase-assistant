class OpenrouterService
  include HTTParty
  base_uri 'https://openrouter.ai/api/v1'

  def initialize
    @headers = {
      'Authorization' => "Bearer #{Rails.application.credentials.openrouter_api_key || ENV['OPENROUTER_API_KEY']}",
      'Content-Type' => 'application/json'
    }
  end

  def chat_completion(message, context = nil)
    api_key = Rails.application.credentials.dig(:openrouter_api_key) || ENV['OPENROUTER_API_KEY']
    
    # If no API key is available, return a helpful fallback response
    unless api_key.present?
      return generate_fallback_response(message, context)
    end

    system_prompt = build_system_prompt(context)
    
    body = {
      model: "meta-llama/llama-3.1-8b-instruct:free",
      messages: [
        {
          role: "system",
          content: system_prompt
        },
        {
          role: "user",
          content: message
        }
      ],
      max_tokens: 1000,
      temperature: 0.7
    }

    @headers['Authorization'] = "Bearer #{api_key}"

    response = self.class.post('/chat/completions', {
      body: body.to_json,
      headers: @headers
    })

    if response.success?
      response.parsed_response.dig("choices", 0, "message", "content")
    else
      Rails.logger.error "OpenRouter API error: #{response.body}"
      generate_fallback_response(message, context)
    end
  rescue => e
    Rails.logger.error "OpenRouter Service error: #{e.message}"
    generate_fallback_response(message, context)
  end

  private

  def generate_fallback_response(message, context)
    # Generate a helpful response without AI when API key is not available
    if context&.any?
      product_names = context.map { |p| p[:name] }.join(", ")
      <<~RESPONSE
        Based on your search, I found these products: #{product_names}

        Here's what I can tell you about your request "#{message}":

        #{analyze_user_intent(message, context)}

        Please note: To get more detailed AI-powered recommendations, an OpenRouter API key needs to be configured.
      RESPONSE
    else
      <<~RESPONSE
        I understand you're looking for help with "#{message}".

        I'm a product purchase assistant that helps you find the best products from Digikala. While I can search for products, I need an OpenRouter API key to provide detailed AI-powered recommendations.

        You can still use me to:
        - Search for specific products
        - Compare prices and ratings
        - Get basic product information

        Try asking me about specific products like "laptop", "phone", or "headphones"!
      RESPONSE
    end
  end

  def analyze_user_intent(message, context)
    # Simple intent analysis for fallback responses
    case message.downcase
    when /laptop|لپ تاپ/
      "For laptops, I recommend considering: processor type (Intel vs AMD), RAM (8GB+ for work), storage (SSD preferred), and screen size (13-15 inches for portability)."
    when /phone|گوشی|موبایل/
      "For smartphones, key factors include: battery life, camera quality, storage capacity, and brand reliability. Consider your budget and intended use."
    when /budget|قیمت|ارزان/
      "Budget is important! Look for the best value proposition - sometimes mid-range products offer better price-to-performance ratios than flagship models."
    else
      "Consider factors like brand reputation, user reviews, warranty, and your specific needs when making a purchase decision."
    end
  end

  def build_system_prompt(context)
    base_prompt = <<~PROMPT
      You are a helpful product purchase assistant specializing in products from Digikala.com. 
      Your role is to help users find the best products based on their needs, comparing prices, 
      features, and providing recommendations.

      When helping users:
      1. Ask clarifying questions about their needs and budget
      2. Provide detailed product comparisons
      3. Highlight pros and cons of different options
      4. Consider price-to-value ratio
      5. Mention any special deals or discounts
      6. Be conversational and helpful

      Always respond in a friendly, informative manner and ask follow-up questions to better understand their needs.
    PROMPT

    if context&.any?
      base_prompt += "\n\nHere are some relevant products I found:\n"
      context.each do |product|
        base_prompt += "- #{product[:name]}: #{product[:price]} (#{product[:rating]} rating) - #{product[:url]}\n"
      end
      base_prompt += "\nUse this information to provide helpful recommendations."
    end

    base_prompt
  end
end