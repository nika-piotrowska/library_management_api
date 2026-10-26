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

    it 'requires exactly six digits in the library card number' do
      reader.library_card_number = '12345'

      expect(reader).not_to be_valid
    end

    it 'rejects library card numbers containing letters' do
      reader.library_card_number = '12345A'

      expect(reader).not_to be_valid
    end

    it 'accepts library card numbers with leading zeros' do
      reader.library_card_number = '000123'

      expect(reader).to be_valid
    end

    it 'requires a unique library card number' do
      existing_reader = create(:reader)

      reader.library_card_number = existing_reader.library_card_number

      expect(reader).not_to be_valid
      expect(reader.errors[:library_card_number]).to be_present
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

  describe 'library card number generation' do
    it 'automatically generates a six-digit library card number' do
      reader = create(:reader)

      expect(reader.library_card_number).to match(/\A[0-9]{6}\z/)
    end

    it 'generates a library card number based on the reader ID' do
      reader = create(:reader)

      expect(reader.library_card_number).to eq(format('%06d', reader.id))
    end

    it 'generates unique library card numbers for different readers' do
      first_reader = create(:reader)
      second_reader = create(:reader)

      expect(first_reader.library_card_number).not_to eq(second_reader.library_card_number)
    end

    it 'generates a library card number when none is provided' do
      reader = described_class.create!(
        full_name: 'Anna Kowalska',
        email: 'anna@example.com'
      )

      expect(reader.library_card_number).to eq(format('%06d', reader.id))
    end

    it 'does not change the library card number when updating a reader' do
      reader = create(:reader)
      original_library_card_number = reader.library_card_number

      reader.update!(full_name: 'Anna Nowak')

      expect(reader.reload.library_card_number).to eq(original_library_card_number)
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
