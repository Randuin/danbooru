module PostSets
  class Post < Base
    attr_reader :tag_array, :page
    
    def initialize(tags, page = 1)
      @tag_array = Tag.scan_query(tags)
      @page = page
    end
    
    def tag_string
      @tag_string ||= tag_array.uniq.join(" ")
    end
    
    def has_wiki?
      tag_array.any? && ::WikiPage.titled(tag_string).exists?
    end
    
    def wiki_page
      if tag_array.any?
        ::WikiPage.titled(tag_string).first
      else
        nil
      end
    end
    
    def posts
      if tag_array.size > 2 && !CurrentUser.is_privileged?
        raise SearchError.new("Upgrade your account to search more than two tags at once")
      end
      
      @posts ||= ::Post.tag_match(tag_string).paginate(page)
    rescue ::Post::SearchError
      @posts = ::Post.where("false")
    end
    
    def has_artist?
      tag_array.any? && ::Artist.name_equals(tag_string).exists?
    end
    
    def artist
      ::Artist.name_equals(tag_string).first
    end
    
    def is_single_tag?
      tag_array.size == 1
    end
    
    def is_empty_tag?
      tag_array.size == 0
    end
    
    def is_pattern_search?
      tag_string =~ /\*/
    end
    
    def current_page
      [page.to_i, 1].max
    end
    
    def presenter
      @presenter ||= ::PostSetPresenters::Post.new(self)
    end
  end
end
