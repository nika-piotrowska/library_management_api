# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'Readers API', type: :request do
  let(:headers) do
    {
      'ACCEPT' => 'application/vnd.api+json',
      'CONTENT_TYPE' => 'application/vnd.api+json'
    }
  end

  describe 'GET /api/v1/readers/:id' do
    let(:reader) { create(:reader) }

    it 'returns a reader in JSON:API format' do
      get "/api/v1/readers/#{reader.id}", headers: headers

      data = JSON.parse(response.body)['data']

      expect(response).to have_http_status(:ok)
      expect(data['type']).to eq('readers')
      expect(data['id']).to eq(reader.id.to_s)
      expect(data['attributes']).to include(
        'library_card_number' => reader.library_card_number,
        'full_name' => reader.full_name,
        'email' => reader.email
      )
    end

    it 'returns JSON:API content type' do
      get "/api/v1/readers/#{reader.id}", headers: headers

      expect(response.media_type).to eq('application/vnd.api+json')
    end

    it 'returns 404 when the reader does not exist' do
      get '/api/v1/readers/999999', headers: headers

      body = JSON.parse(response.body)

      expect(response).to have_http_status(:not_found)
      expect(body['errors']).to be_present
    end
  end

  describe 'POST /api/v1/readers' do
    let(:attributes) do
      {
        full_name: 'Anna Kowalska',
        email: 'anna@example.com'
      }
    end

    let(:payload) do
      {
        data: {
          type: 'readers',
          attributes: attributes
        }
      }
    end

    def create_reader
      post '/api/v1/readers',
           params: payload.to_json,
           headers: headers
    end

    context 'with valid attributes' do
      it 'creates a reader' do
        expect { create_reader }.to change(Reader, :count).by(1)

        expect(response).to have_http_status(:created)
      end

      it 'automatically generates a six-digit library card number' do
        create_reader

        reader = Reader.last

        expect(reader.library_card_number).to match(/\A[0-9]{6}\z/)
        expect(reader.library_card_number).to eq(format('%06d', reader.id))
      end

      it 'returns the created reader in JSON:API format' do
        create_reader

        data = JSON.parse(response.body)['data']
        reader = Reader.last

        expect(data['type']).to eq('readers')
        expect(data['id']).to eq(reader.id.to_s)
        expect(data['attributes']).to include(
          'library_card_number' => reader.library_card_number,
          'full_name' => 'Anna Kowalska',
          'email' => 'anna@example.com'
        )
      end

      it 'generates a unique library card number for each reader' do
        create_reader
        first_library_card_number = Reader.last.library_card_number

        attributes[:email] = 'jan@example.com'
        create_reader
        second_library_card_number = Reader.last.library_card_number

        expect(response).to have_http_status(:created)
        expect(first_library_card_number).not_to eq(second_library_card_number)
      end

      it 'ignores a library card number provided by the client' do
        attributes[:library_card_number] = '999999'

        create_reader

        reader = Reader.last

        expect(response).to have_http_status(:created)
        expect(reader.library_card_number).to eq(format('%06d', reader.id))
        expect(reader.library_card_number).not_to eq('999999')
      end
    end

    context 'with invalid attributes' do
      it 'rejects a missing full name' do
        attributes[:full_name] = nil

        create_reader

        expect(response).to have_http_status(:unprocessable_content)
        expect(JSON.parse(response.body)['errors']).to be_present
      end

      it 'rejects a missing email' do
        attributes[:email] = nil

        create_reader

        expect(response).to have_http_status(:unprocessable_content)
        expect(JSON.parse(response.body)['errors']).to be_present
      end

      it 'rejects an invalid email' do
        attributes[:email] = 'invalid-email'

        create_reader

        expect(response).to have_http_status(:unprocessable_content)
        expect(JSON.parse(response.body)['errors']).to be_present
      end

      it 'rejects a duplicate email regardless of case' do
        create(:reader, email: attributes[:email].upcase)

        create_reader

        expect(response).to have_http_status(:unprocessable_content)
        expect(JSON.parse(response.body)['errors']).to be_present
      end

      it 'does not create a reader when attributes are invalid' do
        attributes[:email] = 'invalid-email'

        expect { create_reader }.not_to change(Reader, :count)
      end
    end

    context 'with invalid JSON:API payload' do
      it 'rejects an incorrect resource type' do
        payload[:data][:type] = 'books'

        create_reader

        expect(response).to have_http_status(:bad_request)
        expect(JSON.parse(response.body)['errors']).to be_present
      end

      it 'rejects a missing data object' do
        post '/api/v1/readers',
             params: { reader: attributes }.to_json,
             headers: headers

        expect(response).to have_http_status(:bad_request)
        expect(JSON.parse(response.body)['errors']).to be_present
      end
    end
  end
end
