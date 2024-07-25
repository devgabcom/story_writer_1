class StoryLlmService
  include ActionView::Helpers::TextHelper
  include UtilityMethods

  def initialize(story)
    @story = story
  end

  def get_story_outline_from_key_elements_prompt(key_elements, num_chapters)
    descriptions = squish_array(key_elements)
    pronoun = descriptions.count > 1 ? 'them' : 'it'
    num_chapters = num_chapters.to_i
    if num_chapters < 1
      num_chapters = 1
    elsif num_chapters > 10
      num_chapters = 10
    end

    system_message = "You are an esteemed creative writer"

    prompt = "I have #{pluralize(descriptions.count, 'description')} of objects, ideas or themes. "
    prompt += "Your task is to read the #{'description'.pluralize(descriptions.count)} and to use #{pronoun} "
    prompt += "as inspiration to draft a short story outline that's suitable for a general audience, "
    prompt += "to suggest a list of #{num_chapters} chapters for the story, and to provide a 1 sentence "
    prompt += "synopsis of what to expect in each chapter. The short story should be fun and witty. "

    prompt += "Return your result as valid JSON (which will be later be parsed by ruby JSON.parse method) "
    prompt += "with the following top-level keys only: 'title', 'outline', 'chapters'. "
    prompt += "And for each chapter use the following keys: 'chapterTitle', 'synopsis'. "
    prompt += "Each field should contain only its information, with no preamble or postamble. "
    prompt += "If any field contains double quotes then they must be escaped. "

    prompt += "The #{'description'.pluralize(descriptions.count)} now follow, enclosed in square brackets: "
    prompt += descriptions.map { |desc| "[#{replace_square_brackets(desc)}]" }.join(', ')

    [{ 'role': 'system', 'content': system_message },
     { 'role': 'user', 'content': prompt }]
  end

  def generate_story_outline(key_elements, num_chapters)
    prompt = get_story_outline_from_key_elements_prompt(key_elements, num_chapters)
    response = agent.chat(prompt, options: default_options)
    JSON.parse(pre_parse_json(agent.format_response(response)))
  end

  def get_write_chapter_prompt(chapter_number, target_chapter_length: 800)
    chapter_number = chapter_number.to_i
    raise "Invalid chapter number" if chapter_number < 1 || chapter_number > @story.chapters.size

    system_message = "You are an esteemed creative writer"
    messages = [{ 'role': 'system', 'content': system_message }]

    user_prompt = "You are in the process of writing a short story called [#{replace_square_brackets(@story.title)}], "
    user_prompt += "which has the following general outline: [#{replace_square_brackets(@story.outline)}], "
    user_prompt += "and the following list of chapters: [#{replace_square_brackets(@story.formatted_chapter_titles)}]. "

    user_prompt += "Your current task is to write chapter #{chapter_number} "
    user_prompt += "[#{replace_square_brackets(@story.find_chapter_by_number(chapter_number).chapter_title)}], "
    user_prompt += "consistent with the outline and other chapters of the story, and in "
    user_prompt += "approximately #{target_chapter_length} words. "

    user_prompt += "Return your result as valid JSON (which will be later be parsed by ruby JSON.parse method) with the following keys only: "
    user_prompt += "'chapterTitle', 'chapterDetail'. "
    user_prompt += "Each field should contain only its information, with no preamble or postamble. "
    user_prompt += "If any field contains double quotes then they must be escaped. "

    messages << { 'role': 'user', 'content': user_prompt }
  end

  def write_chapter(chapter_number, target_chapter_length)
    chapter_messages = get_write_chapter_prompt(chapter_number, target_chapter_length: target_chapter_length)
    response = agent.chat(chapter_messages, options: default_options)
    JSON.parse(pre_parse_json(agent.format_response(response)))
  end

  def write_chapter!(chapter_number, target_chapter_length)
    chapter_json = write_chapter(chapter_number, target_chapter_length)
    @story.update_chapter(chapter_number, chapter_json) if chapter_json&.dig('chapterDetail').present?
  end

  def write_next_chapter(target_chapter_length)
    chapter_number = @story.find_first_nil_chapter
    [chapter_number, write_chapter(chapter_number, target_chapter_length)]
  end

  private

  def agent
    @agent ||= AiAgent::Claude.new(timeout: 60)
  end

  def default_options
    { model: Claude::Model::CLAUDE_CHEAPEST }
  end

  def parse_json(response)
    JSON.parse(response)
  end
end
