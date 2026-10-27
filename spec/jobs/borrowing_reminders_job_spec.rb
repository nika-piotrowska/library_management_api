# frozen_string_literal: true

require 'rails_helper'

RSpec.describe BorrowingRemindersJob, type: :job do
  include ActiveSupport::Testing::TimeHelpers

  let(:reader) { create(:reader) }
  let(:book) { create(:book) }

  before do
    travel_to Time.zone.local(2026, 11, 1, 9)
    ActionMailer::Base.deliveries.clear
  end

  after do
    ActionMailer::Base.deliveries.clear
  end

  describe '#perform' do
    context 'when the due date is in three days' do
      let!(:borrowing) do
        create(
          :borrowing,
          book: book,
          reader: reader,
          due_at: 3.days.from_now
        )
      end

      it 'sends one reminder' do
        expect do
          described_class.perform_now
        end.to change(ActionMailer::Base.deliveries, :count).by(1)
      end

      it 'sends the reminder to the correct reader' do
        described_class.perform_now

        expect(ActionMailer::Base.deliveries.last.to).to eq([reader.email])
      end

      it 'records when the reminder was sent' do
        described_class.perform_now

        expect(borrowing.reload.before_due_reminder_sent_at).to eq(Time.current)
      end

      it 'does not mark the due-date reminder as sent' do
        described_class.perform_now

        expect(borrowing.reload.due_reminder_sent_at).to be_nil
      end

      it 'does not send the same reminder twice' do
        described_class.perform_now

        expect do
          described_class.perform_now
        end.not_to change(ActionMailer::Base.deliveries, :count)
      end
    end

    context 'when the due date is today' do
      let!(:borrowing) do
        create(
          :borrowing,
          book: book,
          reader: reader,
          borrowed_at: 30.days.ago,
          due_at: Time.current
        )
      end

      it 'sends one reminder' do
        expect do
          described_class.perform_now
        end.to change(ActionMailer::Base.deliveries, :count).by(1)
      end

      it 'records when the due-date reminder was sent' do
        described_class.perform_now

        expect(borrowing.reload.due_reminder_sent_at).to eq(Time.current)
      end

      it 'does not send the reminder twice' do
        described_class.perform_now

        expect do
          described_class.perform_now
        end.not_to change(ActionMailer::Base.deliveries, :count)
      end
    end

    context 'when the book was already returned' do
      let!(:borrowing) do
        create(
          :borrowing,
          book: book,
          reader: reader,
          due_at: 3.days.from_now,
          returned_at: Time.current
        )
      end

      it 'does not send a reminder' do
        expect do
          described_class.perform_now
        end.not_to change(ActionMailer::Base.deliveries, :count)
      end

      it 'does not mark the reminder as sent' do
        described_class.perform_now

        expect(borrowing.reload.before_due_reminder_sent_at).to be_nil
      end
    end

    context 'when the due date is in ten days' do
      before do
        create(
          :borrowing,
          book: book,
          reader: reader,
          due_at: 10.days.from_now
        )
      end

      it 'does not send a reminder' do
        expect do
          described_class.perform_now
        end.not_to change(ActionMailer::Base.deliveries, :count)
      end
    end

    context 'when the book is overdue' do
      before do
        create(
          :borrowing,
          book: book,
          reader: reader,
          borrowed_at: 35.days.ago,
          due_at: 5.days.ago
        )
      end

      it 'does not send a scheduled reminder' do
        expect do
          described_class.perform_now
        end.not_to change(ActionMailer::Base.deliveries, :count)
      end
    end

    context 'when several borrowings qualify' do
      before do
        create(:borrowing, due_at: 3.days.from_now)
        create(
          :borrowing,
          borrowed_at: 30.days.ago,
          due_at: Time.current
        )
      end

      it 'sends a reminder for each borrowing' do
        expect do
          described_class.perform_now
        end.to change(ActionMailer::Base.deliveries, :count).by(2)
      end
    end

    context 'when both reminder dates are reached' do
      let!(:borrowing) do
        create(
          :borrowing,
          book: book,
          reader: reader,
          due_at: 3.days.from_now
        )
      end

      it 'sends both reminders on their respective dates' do
        described_class.perform_now

        travel 3.days

        described_class.perform_now

        expect(ActionMailer::Base.deliveries.size).to eq(2)
        expect(borrowing.reload.before_due_reminder_sent_at).to be_present
        expect(borrowing.due_reminder_sent_at).to be_present
      end
    end
  end
end
