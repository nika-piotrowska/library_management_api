# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Reader, type: :model do
  describe 'validations' do
    subject(:reader) { build(:reader) }

    it 'is valid with valid attributes' do
      expect(reader).to be_valid
    end

    it 'requires a full name' do
      reader.full_name = nil

      expect(reader).not_to be_valid
    end

    it 'requires a library card number' do
      reader.library_card_number = nil

      expect(reader).not_to be_valid
    end

    it 'requires exactly six digits in the library card number' do
      reader.library_card_number = '12345'

      expect(reader).not_to be_valid
    end

    it 'accepts library card numbers with leading zeros' do
      reader.library_card_number = '000123'

      expect(reader).to be_valid
    end

    it 'requires a unique library card number' do
      create(:reader, library_card_number: '123456')

      reader.library_card_number = '123456'

      expect(reader).not_to be_valid
    end

    it 'requires an email' do
      reader.email = nil

      expect(reader).not_to be_valid
    end

    it 'rejects an invalid email' do
      reader.email = 'invalid-email'

      expect(reader).not_to be_valid
    end

    it 'requires a unique email' do
      create(:reader, email: 'anna@example.com')

      reader.email = 'anna@example.com'

      expect(reader).not_to be_valid
    end

    it 'validates email uniqueness case-insensitively' do
      create(:reader, email: 'anna@example.com')

      reader.email = 'ANNA@example.com'

      expect(reader).not_to be_valid
    end
  end

  describe 'associations' do
    it 'has many borrowings' do
      reader = create(:reader)
      borrowing = create(:borrowing, reader: reader)

      expect(reader.borrowings).to contain_exactly(borrowing)
    end

    it 'has access to borrowed books' do
      reader = create(:reader)
      book = create(:book)

      create(:borrowing, reader: reader, book: book)

      expect(reader.books).to contain_exactly(book)
    end

    it 'does not allow destroying a reader with borrowing history' do
      reader = create(:reader)
      create(:borrowing, :returned, reader: reader)

      expect(reader.destroy).to be(false)
    end
  end
end
