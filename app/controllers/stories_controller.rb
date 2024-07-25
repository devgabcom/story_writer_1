class StoriesController < ApplicationController
  before_action :set_story, only: [:show, :edit, :write_next_chapter, :finish_story]

  layout 'story', only: [:show]

  def index
    @writing_stories = Story.writing
    @finished_stories = Story.finished
  end

  def show
    if @story.chapters.any? { |chapter| chapter.chapter_detail.nil? }
      redirect_to edit_story_path(@story)
    end
  end

  def edit
  end

  def new
    @story = Story.new
  end

  def create
    key_elements = params[:story][:key_elements].reject(&:blank?)
    num_chapters = params[:story][:num_chapters].to_i

    service = StoryLlmService.new(@story)

    story_outline = service.generate_story_outline(key_elements, num_chapters)
    @story = Story.create_from_outline(story_outline)

    if @story&.persisted?
      redirect_to edit_story_path(@story), notice: 'Story created successfully.'
    else
      render :new
    end
  rescue StandardError => e
    Rails.logger.warn("Exception: #{e.message}")
    flash[:alert] = "Failed to create story: #{e.message}"
    render :new
  end

  def write_next_chapter
    service = StoryLlmService.new(@story)
    chapter_number, chapter_json = service.write_next_chapter(300)
    chapter_hash = Story.camelcase_to_snakecase(chapter_json) if chapter_json.present?

    if chapter_hash.present? &&
      chapter_hash&.dig(:chapter_detail).present? &&
      @story.update_chapter(chapter_number, chapter_json)

      respond_to do |format|
        format.turbo_stream do
          render turbo_stream: turbo_stream.replace("chapter_#{chapter_number}",
                                                    partial: "stories/chapter", locals: { chapter_hash: chapter_hash.merge(chapter_number: chapter_number) })
        end
        format.html { redirect_to edit_story_path(@story), notice: 'Next chapter written successfully.' }
      end
    else
      respond_to do |format|
        format.turbo_stream do
          render turbo_stream: turbo_stream.replace("flash",
                                                    partial: "layouts/flash", locals: { message: 'Failed to write the next chapter.' }),
                 status: :unprocessable_entity
        end
        format.html { redirect_to edit_story_path(@story), alert: 'Failed to write the next chapter.' }
      end
    end
  rescue StandardError => e
    Rails.logger.warn("Exception: #{e.message}")
    flash[:alert] = "Failed to write chapter: #{e.message}"
    render :new
  end

  def finish_story
    service = StoryLlmService.new(@story)

    success = true
    (1..@story.chapters.length).each do
      next unless @story.find_first_nil_chapter

      chapter_number, chapter_json = service.write_next_chapter(300)

      if chapter_json.present? && chapter_json&.dig('chapterDetail').present?
        @story.update_chapter(chapter_number, chapter_json)
      else
        success = false
        break
      end
    end

    if success
      redirect_to edit_story_path(@story), notice: 'Story finished successfully.'
    else
      redirect_to edit_story_path(@story), alert: 'Failed to finish the story.'
    end

  rescue StandardError => e
    Rails.logger.warn("Exception: #{e.message}")
    flash[:alert] = "Failed to finish story: #{e.message}"
    render :new
  end


  private

  def set_story
    @story = Story.find(params[:id])
  end
end