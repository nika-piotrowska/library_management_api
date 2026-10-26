# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'RSpec setup' do
  it 'loads the Rails environment' do
    expect(Rails.env).to eq('test')
  end

  it 'connects to PostgreSQL' do
    expect(
      ActiveRecord::Base.connection.active?
    ).to be(true)
  end

  it 'loads FactoryBot' do
    expect(defined?(FactoryBot)).to eq('constant')
  end
end
