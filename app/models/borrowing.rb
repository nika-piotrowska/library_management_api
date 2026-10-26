# frozen_string_literal: true

class Borrowing < ApplicationRecord
  LOAN_DURATION = 30.days

  belongs_to :book
  belongs_to :reader

  validates :borrowed_at, :due_at, presence: true

  validate :due_at_after_borrowed_at
  validate :returned_at_after_borrowed_at

  scope :active, -> { where(returned_at: nil) }
  scope :returned, -> { where.not(returned_at: nil) }
  scope :recent_first, -> { order(borrowed_at: :desc, id: :desc) }

  before_validation :set_borrowing_dates, on: :create

  def active?
    returned_at.nil?
  end

  def overdue?
    active? && due_at.present? && due_at < Time.current
  end

  private

  def set_borrowing_dates
    self.borrowed_at ||= Time.current
    self.due_at ||= borrowed_at + LOAN_DURATION if borrowed_at.present?
  end

  def due_at_after_borrowed_at
    return if borrowed_at.blank? || due_at.blank?
    return if due_at > borrowed_at

    errors.add(:due_at, 'must be after borrowing date')
  end

  def returned_at_after_borrowed_at
    return if borrowed_at.blank? || returned_at.blank?
    return if returned_at >= borrowed_at

    errors.add(:returned_at, 'cannot be before borrowing date')
  end
end
