# frozen_string_literal: true

require 'rails_helper'

RSpec.describe BorrowingRemindersJob, type: :job do
  include ActiveJob::TestHelper

  it 'uses the default queue' do
    expect(described_class.new.queue_name).to eq('default')
  end

  it 'can be enqueued for background processing' do
    expect do
      described_class.perform_later
    end.to have_enqueued_job(described_class).on_queue('default')
  end
end
