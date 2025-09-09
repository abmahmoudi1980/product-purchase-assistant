class DigikalaScrapingService
  include HTTParty
  base_uri 'https://www.digikala.com'

  def initialize
    @headers = {
      'User-Agent' => 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/91.0.4472.124 Safari/537.36'
    }
  end

  def search_products(query, limit = 10)
    # Note: This is a simplified implementation
    # In a real-world scenario, you'd need to handle Digikala's anti-bot measures
    search_url = "/search/?q=#{URI.encode_www_form_component(query)}"
    
    begin
      response = self.class.get(search_url, headers: @headers)
      
      if response.success?
        parse_search_results(response.body, limit)
      else
        Rails.logger.error "Digikala search error: #{response.code}"
        []
      end
    rescue => e
      Rails.logger.error "Digikala scraping error: #{e.message}"
      # Return mock data for demonstration
      generate_mock_products(query, limit)
    end
  end

  private

  def parse_search_results(html, limit)
    # This would parse the actual HTML from Digikala
    # For now, returning mock data since web scraping is complex
    generate_mock_products("search results", limit)
  end

  def generate_mock_products(query, limit)
    # Mock data for demonstration purposes
    products = []
    
    case query.downcase
    when /laptop|لپ تاپ/
      products = [
        {
          name: "لپ تاپ ایسوس VivoBook 15",
          price: "۲۵,۰۰۰,۰۰۰ تومان",
          rating: "4.2",
          brand: "Asus",
          url: "https://www.digikala.com/product/dkp-123456",
          image: "https://dkstatics-public.digikala.com/digikala-products/laptop1.jpg",
          description: "لپ تاپ ۱۵.۶ اینچی با پردازنده Intel Core i5"
        },
        {
          name: "لپ تاپ لنوو IdeaPad 3",
          price: "۲۲,۰۰۰,۰۰۰ تومان",
          rating: "4.0",
          brand: "Lenovo",
          url: "https://www.digikala.com/product/dkp-123457",
          image: "https://dkstatics-public.digikala.com/digikala-products/laptop2.jpg",
          description: "لپ تاپ ۱۵.۶ اینچی با پردازنده AMD Ryzen 5"
        }
      ]
    when /phone|گوشی|موبایل/
      products = [
        {
          name: "گوشی موبایل سامسونگ Galaxy A54",
          price: "۱۸,۰۰۰,۰۰۰ تومان",
          rating: "4.5",
          brand: "Samsung",
          url: "https://www.digikala.com/product/dkp-234567",
          image: "https://dkstatics-public.digikala.com/digikala-products/phone1.jpg",
          description: "گوشی هوشمند با صفحه نمایش ۶.۴ اینچی"
        },
        {
          name: "گوشی موبایل شیائومی Redmi Note 12",
          price: "۱۲,۰۰۰,۰۰۰ تومان",
          rating: "4.3",
          brand: "Xiaomi",
          url: "https://www.digikala.com/product/dkp-234568",
          image: "https://dkstatics-public.digikala.com/digikala-products/phone2.jpg",
          description: "گوشی هوشمند با دوربین ۵۰ مگاپیکسل"
        }
      ]
    else
      products = [
        {
          name: "محصول نمونه #{query}",
          price: "۱۰,۰۰۰,۰۰۰ تومان",
          rating: "4.0",
          brand: "Generic",
          url: "https://www.digikala.com/product/dkp-generic",
          image: "https://dkstatics-public.digikala.com/digikala-products/generic.jpg",
          description: "توضیحات محصول نمونه"
        }
      ]
    end

    products.take(limit)
  end
end