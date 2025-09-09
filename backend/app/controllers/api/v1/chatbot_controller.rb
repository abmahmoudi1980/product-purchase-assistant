class Api::V1::ChatbotController < ApplicationController
  def chat
    message = params[:message]
    product_query = params[:product_query]

    if message.blank?
      render json: { error: "Message cannot be blank" }, status: :bad_request
      return
    end

    # Search for products if the message seems to be about products
    context = nil
    if should_search_products?(message) || product_query.present?
      search_term = product_query.present? ? product_query : extract_product_keywords(message)
      if search_term.present?
        digikala_service = DigikalaScrapingService.new
        context = digikala_service.search_products(search_term, 5)
      end
    end

    # Get AI response
    openrouter_service = OpenrouterService.new
    ai_response = openrouter_service.chat_completion(message, context)

    render json: {
      response: ai_response,
      products: context || [],
      searched_for: product_query || extract_product_keywords(message)
    }
  rescue => e
    Rails.logger.error "Chatbot error: #{e.message}"
    render json: { 
      error: "Sorry, I encountered an error. Please try again.",
      response: "I'm having trouble processing your request right now. Please try again in a moment."
    }, status: :internal_server_error
  end

  private

  def should_search_products?(message)
    product_keywords = [
      'خرید', 'buy', 'purchase', 'product', 'محصول', 'قیمت', 'price',
      'laptop', 'لپ تاپ', 'phone', 'گوشی', 'موبایل', 'تلویزیون', 'tv',
      'headphone', 'هدفون', 'کتاب', 'book', 'clothes', 'لباس'
    ]
    
    product_keywords.any? { |keyword| message.downcase.include?(keyword.downcase) }
  end

  def extract_product_keywords(message)
    # Simple keyword extraction - in a real app this would be more sophisticated
    message_lower = message.downcase
    
    # Check for specific product types
    if message_lower.include?('laptop') || message_lower.include?('لپ تاپ')
      return 'laptop'
    elsif message_lower.include?('phone') || message_lower.include?('گوشی') || message_lower.include?('موبایل')
      return 'phone'
    elsif message_lower.include?('headphone') || message_lower.include?('هدفون')
      return 'headphone'
    elsif message_lower.include?('tv') || message_lower.include?('تلویزیون')
      return 'tv'
    elsif message_lower.include?('book') || message_lower.include?('کتاب')
      return 'book'
    end
    
    # Fallback: extract meaningful words
    words = message.split(/\s+/)
    product_words = words.select do |word|
      word.length > 2 && !['and', 'or', 'the', 'a', 'an', 'و', 'یا', 'که', 'for', 'need', 'want', 'help', 'finding', 'good', 'best'].include?(word.downcase)
    end
    
    # Return the most relevant keywords
    product_words.take(2).join(' ')
  end
end
