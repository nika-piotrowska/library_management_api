# frozen_string_literal: true

require 'rails_helper'

RSpec.describe BorrowingMailer, type: :mailer do
  let(:reader) { create(:reader, full_name: 'Anna Kowalska') }
  let(:book) { create(:book, title: 'Dune', author: 'Frank Herbert') }

  let(:borrowing) do
    create(
      :borrowing,
      book: book,
      reader: reader,
      due_at: 3.days.from_now
    )
  end

  describe '#before_due_reminder' do
    subject(:email) do
      described_class.before_due_reminder(borrowing)
    end

    it 'sends the email to the reader' do
      expect(email.to).to eq([reader.email])
    end

    it 'includes the book title in the subject' do
      expect(email.subject).to include('Dune')
    end

    it 'includes the reader name' do
      expect(email.body.decoded).to include('Anna Kowalska')
    end

    it 'includes the book information' do
      expect(email.body.decoded).to include(
        'Dune',
        'Frank Herbert',
        book.serial_number
      )
    end

    it 'includes the due date' do
      expect(email.body.decoded).to include(
        borrowing.due_at.to_date.to_s
      )
    end

    it 'mentions the three-day reminder' do
      expect(email.body.decoded).to include('3 days')
    end

    it 'can be delivered' do
      expect do
        email.deliver_now
      end.to change(ActionMailer::Base.deliveries, :count).by(1)
    end
  end

  describe '#due_reminder' do
    subject(:email) do
      described_class.due_reminder(borrowing)
    end

    it 'sends the email to the reader' do
      expect(email.to).to eq([reader.email])
    end

    it 'includes the book title in the subject' do
      expect(email.subject).to include('Dune')
    end

    it 'indicates that the book is due today' do
      expect(email.subject).to include('due today')
    end

    it 'includes the reader name' do
      expect(email.body.decoded).to include('Anna Kowalska')
    end

    it 'includes the book information' do
      expect(email.body.decoded).to include(
        'Dune',
        'Frank Herbert',
        book.serial_number
      )
    end

    it 'includes the due date' do
      expect(email.body.decoded).to include(
        borrowing.due_at.to_date.to_s
      )
    end

    it 'asks the reader to return the book today' do
      expect(email.body.decoded).to include('return the book today')
    end

    it 'can be delivered' do
      expect do
        email.deliver_now
      end.to change(ActionMailer::Base.deliveries, :count).by(1)
    end
  end
end
