Rails.application.routes.draw do
  resources :stories do
    member do
      post :write_next_chapter
      post :finish_story
    end
  end
  root 'stories#index'
end