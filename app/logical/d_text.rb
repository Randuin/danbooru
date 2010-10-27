require 'cgi'

class DText
  def self.parse_inline(str, options = {})
    str = parse_aliased_wiki_links(str)
    str = parse_wiki_links(str)
    str = parse_post_links(str)
    str = parse_id_links(str)
    
    str.gsub!(/\n/m, "<br>")
    str.gsub!(/\[b\](.+?)\[\/b\]/i, '<strong>\1</strong>')
    str.gsub!(/\[i\](.+?)\[\/i\]/i, '<em>\1</em>')
    str.gsub!(/\[spoilers?\](.+?)\[\/spoilers?\]/m, '<span class="spoiler">\1</span>')
    str.gsub!(/\[url\](.+?)\[\/url\]/i) do
      %{<a href="#{u($1)}">#{h($1)}</a>}
    end
    str.gsub!(/\[url=(.+?)\](.+?)\[\/url\]/m) do
      %{<a href="#{u($1)}">#{h($2)}</a>}
    end
    str
  end
  
  def self.parse_aliased_wiki_links(str)
    str.gsub(/\[\[(.+?)\|(.+?)\]\]/m) do
      text = $1
      title = $2
      wiki_page = WikiPage.find_title_and_id(title)
      
      if wiki_page
        %{[url=/wiki_pages/#{wiki_page.id}]#{text}[/url]}
      else
        %{[url=/wiki_pages/new?title=#{title}]#{text}[/url]}
      end
    end
  end
  
  def self.parse_wiki_links(str)
    str.gsub(/\[\[(.+?)\]\]/) do
      title = $1
      wiki_page = WikiPage.find_title_and_id(title)
      
      if wiki_page
        %{[url=/wiki_pages/#{wiki_page.id}]#{title}[/url]}
      else
        %{[url=/wiki_pages/new?title=#{title}]#{title}[/url]}
      end
    end
  end
  
  def self.parse_post_links(str)
    str.gsub(/\{\{(.+?)\}\}/, %{[url=/posts?tags=\1]\1[/url]})
  end
  
  def self.parse_id_links(str)
    str = str.gsub(/\bpost #(\d+)/i, %{[url=/posts/\1]post #\1[/url]})
    str = str.gsub(/\bforum #(\d+)/i, %{[url=/forum_posts/\1]forum #\1[/url]})
    str = str.gsub(/\bcomment #(\d+)/i, %{[url=/comments/\1]comment #\1[/url]})
    str = str.gsub(/\bpool #(\d+)/i, %{[url=/pools/\1]pool #\1[/url]})
  end
  
  def self.parse_list(str, options = {})
    html = ""
    layout = []
    nest = 0

    str.split(/\n/).each do |line|
      if line =~ /^\s*(\*+) (.+)/
        nest = $1.size
        content = parse_inline($2)
      else
        content = parse_inline(line)
      end

      if nest > layout.size
        html += "<ul>"
        layout << "ul"
      end

      while nest < layout.size
        elist = layout.pop
        if elist
          html += "</#{elist}>"
        end
      end

      html += "<li>#{content}</li>"
    end

    while layout.any?
      elist = layout.pop
      html += "</#{elist}>"
    end

    html
  end

  def self.parse(str, options = {})
    return "" if str.blank?
    
    # Make sure quote tags are surrounded by newlines
    
    unless options[:inline]
      str.gsub!(/\s*\[quote\]\s*/m, "\n\n[quote]\n\n")
      str.gsub!(/\s*\[\/quote\]\s*/m, "\n\n[/quote]\n\n")
    end
    
    str.gsub!(/(?:\r?\n){3,}/, "\n\n")
    str.strip!
    blocks = str.split(/(?:\r?\n){2}/)
    
    html = blocks.map do |block|
      case block
      when /^(h[1-6])\.\s*(.+)$/
        tag = $1
        content = $2      
          
        if options[:inline]
          "<h6>" + parse_inline(content, options) + "</h6>"
        else
          "<#{tag}>" + parse_inline(content, options) + "</#{tag}>"
        end

      when /^\s*\*+ /
        parse_list(block, options)
        
      when "[quote]"
        if options[:inline]
          ""
        else
          '<blockquote>'
        end
        
      when "[/quote]"
        if options[:inline]
          ""
        else
          '</blockquote>'
        end

      else
        '<p>' + parse_inline(block) + "</p>"
      end
    end

    html.join("").html_safe
  end
end
