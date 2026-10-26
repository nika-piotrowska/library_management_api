# frozen_string_literal: true

FactoryBot.define do
  factory :borrowing do
    book
    reader

    borrowed_at { Time.current }
    due_at { borrowed_at + 30.days }
    returned_at { nil }

    trait :returned do
      returned_at { borrowed_at + 10.days }
    end

    trait :overdue do
      borrowed_at { 40.days.ago }
      due_at { borrowed_at + 30.days }
    end
  end
end
