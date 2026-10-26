# frozen_string_literal: true

FactoryBot.define do
  factory :reader do
    full_name { Faker::Name.name }
    sequence(:email) { |n| Faker::Internet.email(name: "reader#{n}") }
  end
end
