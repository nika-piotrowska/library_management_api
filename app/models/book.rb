# frozen_string_literal: true

class Book < ApplicationRecord
  MAX_SERIAL_NUMBER = 999_999

  has_many :borrowings, dependent: :restrict_with_error
  has_many :readers, through: :borrowings

  before_validation :generate_serial_number, on: :create

  validates :serial_number,
            presence: true,
            uniqueness: true,
            format: { with: /\A[0-9]{6}\z/ }

  validates :title, :author, presence: true

  scope :active, -> { where(archived_at: nil) }
  scope :archived, -> { where.not(archived_at: nil) }
  scope :available, lambda {
    active.where.not(
      id: Borrowing.where(returned_at: nil).select(:book_id)
    )
  }

  def current_borrowing
    borrowings.find_by(returned_at: nil)
  end

  def available?
    !archived? && current_borrowing.nil?
  end

  def archived?
    archived_at.present?
  end

  private

  def generate_serial_number
    return if serial_number.present?

    name = sequence_name
    n_id = next_id(name)

    if n_id > MAX_SERIAL_NUMBER
      errors.add(:serial_number, 'number range exhausted')
      return
    end

    self.id = n_id
    self.serial_number = format('%06d', n_id)
  end

  def sequence_name
    self.class.connection.quote(
      self.class.connection.select_value(
        "SELECT pg_get_serial_sequence('books', 'id')"
      )
    )
  end

  def next_id(name)
    self.class.connection.select_value(
      "SELECT nextval(#{name})"
    ).to_i
  end
end
