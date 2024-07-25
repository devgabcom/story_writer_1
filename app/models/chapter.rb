class Chapter
  include ActiveModel::Model
  include ActiveModel::Validations

  attr_accessor :chapter_title, :synopsis, :chapter_detail, :chapter_number

  validates :chapter_title, presence: true
  validates :synopsis, presence: true
  validates :chapter_number, presence: true, numericality: { only_integer: true, greater_than: 0 }

  def initialize(attributes = {})
    @chapter_title = attributes[:chapter_title]
    @synopsis = attributes[:synopsis]
    @chapter_detail = attributes[:chapter_detail]
    @chapter_number = attributes[:chapter_number]
  end

  def attributes
    {
      chapter_title: @chapter_title,
      synopsis: @synopsis,
      chapter_detail: @chapter_detail,
      chapter_number: @chapter_number
    }
  end
end
