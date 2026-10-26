# frozen_string_literal: true

class Book < ApplicationRecord
  validates :serial_number,
            presence: true,
            uniqueness: true,
            format: { with: /\A[0-9]{6}\z/ }

  validates :title, :author, presence: true

  scope :active, -> { where(archived_at: nil) }
  scope :archived, -> { where.not(archived_at: nil) }

  def archived?
    archived_at.present?
  end
end
