# frozen_string_literal: true

FactoryBot.define do
  factory :book do
    sequence(:serial_number) { |n| format('%06d', n) }

    title { Faker::Book.title }
    author { Faker::Book.author }

    trait :archived do
      archived_at { Time.current }
    end
  end
end
