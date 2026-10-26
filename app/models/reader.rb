# frozen_string_literal: true

class Reader < ApplicationRecord
  has_many :borrowings, dependent: :restrict_with_error
  has_many :books, through: :borrowings

  validates :library_card_number,
            presence: true,
            uniqueness: true,
            format: { with: /\A[0-9]{6}\z/ }

  validates :full_name, presence: true

  validates :email,
            presence: true,
            uniqueness: { case_sensitive: false },
            format: { with: URI::MailTo::EMAIL_REGEXP }
end
