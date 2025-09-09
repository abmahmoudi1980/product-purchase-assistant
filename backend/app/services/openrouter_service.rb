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
      model: "deepseek/deepseek-chat-v3.1:free",
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
      product_names = context.map { |p| p[:name] }.join("، ")
      <<~RESPONSE
        بر اساس جستجوی شما، این محصولات را یافتم: #{product_names}

        درباره درخواست شما "#{message}" می‌توانم بگویم:

        #{analyze_user_intent(message, context)}

        توجه: برای دریافت توصیه‌های دقیق‌تر هوش مصنوعی، نیاز به تنظیم کلید API OpenRouter است.
      RESPONSE
    else
      <<~RESPONSE
        درخواست شما "#{message}" را متوجه شدم.

        من یک دستیار خرید محصولات هستم که به شما کمک می‌کنم بهترین محصولات را از دیجی‌کالا پیدا کنید. در حالی که می‌توانم محصولات را جستجو کنم، برای ارائه توصیه‌های دقیق هوش مصنوعی به کلید API OpenRouter نیاز دارم.

        هنوز هم می‌توانید از من استفاده کنید برای:
        - جستجوی محصولات خاص
        - مقایسه قیمت‌ها و امتیازات
        - دریافت اطلاعات پایه محصولات

        از من درباره محصولات خاصی مثل "لپ تاپ"، "گوشی" یا "هدفون" بپرسید!
      RESPONSE
    end
  end

  def analyze_user_intent(message, context)
    # Simple intent analysis for fallback responses
    case message.downcase
    when /laptop|لپ تاپ/
      "برای لپ تاپ‌ها توصیه می‌کنم این موارد را در نظر بگیرید: نوع پردازنده (Intel در مقابل AMD)، رم (حداقل ۸ گیگابایت برای کار)، حافظه (SSD ترجیحی)، و اندازه صفحه نمایش (۱۳-۱۵ اینچ برای قابلیت حمل)."
    when /phone|گوشی|موبایل/
      "برای گوشی‌های هوشمند، عوامل کلیدی شامل: عمر باتری، کیفیت دوربین، ظرفیت حافظه، و قابلیت اعتماد برند است. بودجه و نحوه استفاده‌تان را در نظر بگیرید."
    when /budget|قیمت|ارزان/
      "بودجه مهم است! به دنبال بهترین ارزش در مقابل قیمت باشید - گاهی محصولات میان‌رده نسبت قیمت به عملکرد بهتری نسبت به محصولات پرچمدار ارائه می‌دهند."
    else
      "عواملی مثل شهرت برند، نظرات کاربران، گارانتی، و نیازهای خاص خود را هنگام تصمیم‌گیری برای خرید در نظر بگیرید."
    end
  end

  def build_system_prompt(context)
    base_prompt = <<~PROMPT
      You are a helpful product purchase assistant specializing in products from Digikala.com. 
      Your role is to help users find the best products based on their needs, comparing prices, 
      features, and providing recommendations.

      When helping users:
      1. Analyze the product information provided and give detailed comparisons
      2. Ask clarifying questions about their specific needs and budget
      3. Highlight pros and cons of different options based on the data
      4. Consider price-to-value ratio and recommend the best options
      5. Mention any notable features, ratings, or brands
      6. Be conversational and helpful
      7. Suggest which product might be best for different use cases

      Always respond in Persian (Farsi) language and in a friendly, informative manner. 
      Use the actual product data to make specific recommendations and comparisons.
    PROMPT

    if context&.any?
      base_prompt += "\n\nHere are the products I found from Digikala search:\n"
      context.each do |product|
        base_prompt += "- نام: #{product[:name]}\n"
        base_prompt += "  قیمت: #{product[:price]}\n"
        base_prompt += "  امتیاز: #{product[:rating]}\n"
        base_prompt += "  برند: #{product[:brand]}\n"
        base_prompt += "  توضیحات: #{product[:description]}\n"
        base_prompt += "  لینک: #{product[:url]}\n\n"
      end
      base_prompt += "\nPlease analyze these products and provide helpful recommendations based on the user's query. Compare prices, features, ratings, and brands to help them make the best choice."
    else
      base_prompt += "\n\nNo specific products were found. Please help the user refine their search or suggest general product categories."
    end

    base_prompt
  end
end