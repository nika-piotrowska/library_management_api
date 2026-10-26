# frozen_string_literal: true

FactoryBot.define do
  factory :reader do
    sequence(:library_card_number) { |n| format('%06d', n) }

    full_name { Faker::Name.name }
    sequence(:email) { |n| Faker::Internet.email(name: "reader#{n}") }
  end
end
