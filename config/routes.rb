# frozen_string_literal: true

Rails.application.routes.draw do
  mount LetterOpenerWeb::Engine, at: '/letter_opener' if Rails.env.development?

  namespace :api do
    namespace :v1 do
      resources :books, only: %i[index show create destroy]
      resources :readers, only: %i[show create]

      resources :borrowings, only: %i[create] do
        post :return, on: :member, action: :return_book
      end
    end
  end
end
