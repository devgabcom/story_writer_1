module UtilityMethods
  def replace_square_brackets(input_string)
    input_string.gsub('[', '(').gsub(']', ')')
  end

  def squish_array(arr)
    arr.compact.collect(&:squish).reject(&:empty?)
  end

  def array_list_to_string(array_list)
    return '' if array_list.blank?

    case array_list.length
    when 1
      array_list.first
    when 2
      array_list.join(" and ")
    else
      "#{array_list[0...-1].join(', ')}, and #{array_list.last}"
    end
  end

  def unescape_text(text)
    text.gsub('"', '&quot;')
  end

  # fixes for common errors in the JSON data returned through the API
  def pre_parse_json(input_string, key_names = [])
    in_string = false
    escaped = false
    result = ''
    buffer = ''

    input_string.each_char.with_index do |char, index|
      if escaped
        buffer << char
        escaped = false
      elsif char == '\\'
        buffer << char
        escaped = true
      elsif char == '"'
        if in_string
          lookahead = input_string[index + 1, 20]
          if lookahead.match(/^\s*[,:}\]]/) || key_names.any? { |key| lookahead.include?(key) }
            in_string = false
            result << buffer << char
            buffer = ''
          else
            buffer << '\\' << char
          end
        else
          in_string = true
          result << buffer << char
          buffer = ''
        end
      elsif char == "\n" && in_string
        buffer << '\\n'
      elsif char == "\n" && !in_string
        result << buffer << "\n"
        buffer = ''
      elsif char == "\r"
        # Ignore carriage returns
      elsif char == ' ' && !in_string
        # Skip whitespace outside of strings
      else
        buffer << char
      end
    end

    result << buffer
    result.gsub(/(?<!\\)\\n/, '\\\\n') # Double escape single escaped newlines
  end
end