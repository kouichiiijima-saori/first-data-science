require "commonmarker"
require "nokogiri"
require "uri"

class MarkdownRenderer
  OPTIONS = {
    extension: {
      table: true,
      tagfilter: true,
      header_ids: nil
    },
    render: {
      hardbreaks: false,
      github_pre_lang: false,
      unsafe: false
    }
  }.freeze
  PLUGINS = { syntax_highlighter: nil }.freeze

  ALLOWED_TAGS = %w[
    h1 h2 h3 h4 h5 h6 p br strong em ul ol li a blockquote code pre table thead tbody tr th td hr img
  ].freeze
  ALLOWED_ATTRIBUTES = %w[href title target rel src alt class].freeze
  ALLOWED_LINK_SCHEMES = %w[http https mailto].freeze
  CODE_LANGUAGE_CLASS = /\Alanguage-[A-Za-z0-9_+-]+\z/

  class << self
    def render(markdown)
      new.render(markdown)
    end
  end

  def render(markdown)
    html = Commonmarker.to_html(markdown.to_s.encode("UTF-8"), options: OPTIONS, plugins: PLUGINS)
    html = sanitizer.sanitize(html, tags: ALLOWED_TAGS, attributes: ALLOWED_ATTRIBUTES)

    post_process(html)
  rescue ArgumentError, TypeError
    ""
  end

  private
    def sanitizer
      @sanitizer ||= Rails::HTML5::SafeListSanitizer.new
    end

    def post_process(html)
      fragment = Nokogiri::HTML5.fragment(html)

      normalize_classes(fragment)
      normalize_links(fragment)
      normalize_images(fragment)

      fragment.to_html.html_safe
    end

    def normalize_classes(fragment)
      fragment.css("*").each do |node|
        next unless node.attribute("class")

        classes = node["class"].to_s.split.select { |class_name| allowed_class?(node, class_name) }
        if classes.any?
          node["class"] = classes.join(" ")
        else
          node.remove_attribute("class")
        end
      end
    end

    def allowed_class?(node, class_name)
      node.name == "code" && class_name.match?(CODE_LANGUAGE_CLASS)
    end

    def normalize_links(fragment)
      fragment.css("a").each do |node|
        href = node["href"].to_s
        node.remove_attribute("href") unless allowed_link_href?(href)

        next unless node["target"] == "_blank"

        node["rel"] = "noopener noreferrer"
      end
    end

    def allowed_link_href?(href)
      return false if href.blank?
      return true if same_origin_path?(href)

      uri = URI.parse(href)
      ALLOWED_LINK_SCHEMES.include?(uri.scheme)
    rescue URI::InvalidURIError
      false
    end

    def normalize_images(fragment)
      fragment.css("img").each do |node|
        node.remove unless allowed_image_src?(node["src"].to_s)
      end
    end

    def allowed_image_src?(src)
      same_origin_path?(src)
    end

    def same_origin_path?(value)
      value.start_with?("/") && !value.start_with?("//")
    end
end
