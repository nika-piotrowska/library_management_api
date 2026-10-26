# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Book, type: :model do
  describe 'validations' do
    subject(:book) { build(:book) }

    it 'is valid with valid attributes' do
      expect(book).to be_valid
    end

    it 'requires a title' do
      book.title = nil

      expect(book).not_to be_valid
      expect(book.errors[:title]).to be_present
    end

    it 'requires an author' do
      book.author = nil

      expect(book).not_to be_valid
      expect(book.errors[:author]).to be_present
    end

    it 'requires a serial number' do
      book.serial_number = nil

      expect(book).not_to be_valid
    end

    it 'requires exactly six digits in the serial number' do
      book.serial_number = '12345'

      expect(book).not_to be_valid
    end

    it 'rejects serial numbers containing letters' do
      book.serial_number = '12345A'

      expect(book).not_to be_valid
    end

    it 'accepts serial numbers with leading zeros' do
      book.serial_number = '000123'

      expect(book).to be_valid
    end

    it 'requires a unique serial number' do
      create(:book, serial_number: '123456')

      book.serial_number = '123456'

      expect(book).not_to be_valid
      expect(book.errors[:serial_number]).to be_present
    end
  end

  describe 'scopes' do
    let!(:active_book) { create(:book) }
    let!(:archived_book) { create(:book, :archived) }

    it 'returns only active books' do
      expect(described_class.active).to contain_exactly(active_book)
    end

    it 'returns only archived books' do
      expect(described_class.archived).to contain_exactly(archived_book)
    end
  end

  describe '#archived?' do
    it 'returns false for an active book' do
      book = build(:book)

      expect(book.archived?).to be(false)
    end

    it 'returns true for an archived book' do
      book = build(:book, :archived)

      expect(book.archived?).to be(true)
    end
  end

  describe 'associations' do
    it 'has many borrowings' do
      book = create(:book)
      borrowing = create(:borrowing, book: book)

      expect(book.borrowings).to contain_exactly(borrowing)
    end

    it 'does not allow destroying a book with borrowing history' do
      book = create(:book)
      create(:borrowing, :returned, book: book)

      expect(book.destroy).to be(false)
      expect(book.errors).to be_present
    end
  end

  describe '#available?' do
    it 'returns true for a book without active borrowings' do
      book = create(:book)

      expect(book.available?).to be(true)
    end

    it 'returns false for a borrowed book' do
      book = create(:book)
      create(:borrowing, book: book)

      expect(book.available?).to be(false)
    end

    it 'returns true after the book is returned' do
      book = create(:book)
      create(:borrowing, :returned, book: book)

      expect(book.available?).to be(true)
    end

    it 'returns false for an archived book' do
      book = create(:book, :archived)

      expect(book.available?).to be(false)
    end
  end

  describe '.available' do
    it 'returns only available and non-archived books' do
      available_book = create(:book)
      borrowed_book = create(:book)
      create(:book, :archived)
      create(:borrowing, book: borrowed_book)

      expect(described_class.available).to contain_exactly(available_book)
    end
  end
end
