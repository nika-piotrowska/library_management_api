# frozen_string_literal: true

class Book < ApplicationRecord
  has_many :borrowings, dependent: :restrict_with_error
  has_many :readers, through: :borrowings

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
end
