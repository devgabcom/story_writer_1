class Story < ApplicationRecord
  validate :chapters_format

  include CaseConversion
  include UtilityMethods

  scope :writing, -> { where("chapters @> '[{\"chapter_detail\": null}]'") }
  scope :finished, -> { where.not(id: writing.pluck(:id)) }

  def chapters
    read_attribute(:chapters).map { |chapter_data| Chapter.new(chapter_data.symbolize_keys) }.sort_by(&:chapter_number)
  end

  def chapters=(attributes)
    write_attribute(:chapters, attributes.map { |attr| attr.symbolize_keys })
    @chapters = nil  # Reset the cached chapters array
  end

  def self.create_from_outline(story_outline)
    story = {
      title: story_outline['title'],
      outline: story_outline['outline'],
      chapters: story_outline['chapters'].each_with_index.map do |chapter, index|
        camelcase_to_snakecase(chapter).merge(chapter_detail: nil, chapter_number: index + 1)
      end
    }
    Story.create!(story)
  end

  def update_chapter(chapter_number, new_content)
    chapters_data = read_attribute(:chapters)
    chapter_index = chapters_data.find_index { |chapter| chapter['chapter_number'] == chapter_number }
    if chapter_index
      chapters_data[chapter_index].merge!(self.class.camelcase_to_snakecase(new_content))
      write_attribute(:chapters, chapters_data)
      save!
    else
      errors.add(:chapters, 'Invalid chapter number')
      false
    end
  end

  def find_first_nil_chapter
    unwritten_chapter = chapters.find { |chapter| chapter.chapter_detail.nil? }
    unwritten_chapter&.chapter_number
  end

  def find_chapter_by_number(chapter_number)
    chapters.find { |chapter| chapter.chapter_number == chapter_number }
  end

  def formatted_chapter_titles
    titles = chapters.map(&:chapter_title)
    array_list_to_string(titles)
  end

  private

  def chapters_format
    unless read_attribute(:chapters).is_a?(Array) && read_attribute(:chapters).all? { |chapter| chapter.is_a?(Hash) }
      errors.add(:chapters, 'must be an array of hashes')
    end
  end

end
