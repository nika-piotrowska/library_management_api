# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Borrowing, type: :model do
  describe 'associations' do
    it 'belongs to a book' do
      borrowing = build(:borrowing, book: nil)

      expect(borrowing).not_to be_valid
    end

    it 'belongs to a reader' do
      borrowing = build(:borrowing, reader: nil)

      expect(borrowing).not_to be_valid
    end
  end

  describe 'borrowing dates' do
    it 'automatically sets the borrowing date' do
      borrowing = build(:borrowing, borrowed_at: nil, due_at: nil)

      borrowing.valid?

      expect(borrowing.borrowed_at).to be_present
    end

    it 'sets the due date to 30 days after borrowing' do
      borrowing = build(:borrowing, borrowed_at: nil, due_at: nil)

      borrowing.valid?

      expect(borrowing.due_at).to eq(borrowing.borrowed_at + 30.days)
    end

    it 'rejects a due date before the borrowing date' do
      borrowing = build(
        :borrowing,
        borrowed_at: Time.current,
        due_at: 1.day.ago
      )

      expect(borrowing).not_to be_valid
      expect(borrowing.errors[:due_at]).to be_present
    end

    it 'rejects a return date before the borrowing date' do
      borrowing = build(
        :borrowing,
        returned_at: 1.day.ago
      )

      expect(borrowing).not_to be_valid
      expect(borrowing.errors[:returned_at]).to be_present
    end
  end

  describe '#active?' do
    it 'returns true for an active borrowing' do
      borrowing = build(:borrowing)

      expect(borrowing.active?).to be(true)
    end

    it 'returns false for a returned borrowing' do
      borrowing = build(:borrowing, :returned)

      expect(borrowing.active?).to be(false)
    end
  end

  describe '#overdue?' do
    it 'returns true for an overdue borrowing' do
      borrowing = build(:borrowing, :overdue)

      expect(borrowing.overdue?).to be(true)
    end

    it 'returns false for a borrowing that is not overdue' do
      borrowing = build(:borrowing)

      expect(borrowing.overdue?).to be(false)
    end

    it 'returns false for an already returned book' do
      borrowing = build(:borrowing, :returned)

      expect(borrowing.overdue?).to be(false)
    end
  end

  describe 'borrowing history' do
    let(:book) { create(:book) }

    it 'allows multiple historical borrowings of the same book' do
      first = create(:borrowing, :returned, book: book)
      second = create(:borrowing, :returned, book: book)

      expect(book.borrowings).to contain_exactly(first, second)
    end

    it 'allows a new borrowing after the previous one is returned' do
      create(:borrowing, :returned, book: book)

      borrowing = build(:borrowing, book: book)

      expect(borrowing.save).to be(true)
    end

    it 'allows only one active borrowing per book' do
      create(:borrowing, book: book)

      expect do
        create(:borrowing, book: book)
      end.to raise_error(ActiveRecord::RecordNotUnique)
    end

    it 'keeps historical borrowings after a book is returned' do
      borrowing = create(:borrowing, book: book)

      borrowing.update!(returned_at: Time.current)

      expect(book.borrowings.count).to eq(1)
      expect(book.borrowings.first.returned_at).to be_present
    end
  end
end
