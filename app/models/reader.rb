# frozen_string_literal: true

class Reader < ApplicationRecord
  MAX_LIBRARY_CARD_NUMBER = 999_999

  has_many :borrowings, dependent: :restrict_with_error
  has_many :books, through: :borrowings

  before_validation :generate_library_card_number, on: :create

  validates :library_card_number,
            presence: true,
            uniqueness: true,
            format: { with: /\A[0-9]{6}\z/ }

  validates :full_name, presence: true
  validates :email,
            presence: true,
            uniqueness: { case_sensitive: false },
            format: { with: URI::MailTo::EMAIL_REGEXP }

  private

  def generate_library_card_number
    return if library_card_number.present?

    n_id = next_id

    if n_id > MAX_LIBRARY_CARD_NUMBER
      errors.add(:library_card_number, 'number range exhausted')
      return
    end

    self.id = n_id
    self.library_card_number = format('%06d', n_id)
  end

  def next_id
    self.class.connection.select_value(
      "SELECT nextval(pg_get_serial_sequence('readers', 'id'))"
    ).to_i
  end
end
