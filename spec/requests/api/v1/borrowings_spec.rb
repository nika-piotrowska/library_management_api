# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'Borrowings API', type: :request do
  let(:book) { create(:book) }
  let(:reader) { create(:reader) }

  let(:headers) do
    {
      'ACCEPT' => 'application/vnd.api+json',
      'CONTENT_TYPE' => 'application/vnd.api+json'
    }
  end

  let(:payload) do
    {
      data: {
        type: 'borrowings',
        relationships: {
          book: {
            data: { type: 'books', id: book.id.to_s }
          },
          reader: {
            data: { type: 'readers', id: reader.id.to_s }
          }
        }
      }
    }
  end

  def create_borrowing
    post '/api/v1/borrowings',
         params: payload.to_json,
         headers: headers
  end

  describe 'POST /api/v1/borrowings' do
    context 'with valid attributes' do
      it 'creates a borrowing' do
        expect { create_borrowing }.to change(Borrowing, :count).by(1)

        expect(response).to have_http_status(:created)
      end

      it 'sets the due date to 30 days after borrowing' do
        create_borrowing

        borrowing = Borrowing.last

        expect(borrowing.due_at).to eq(borrowing.borrowed_at + 30.days)
      end

      it 'returns a borrowing in JSON:API format' do
        create_borrowing

        data = JSON.parse(response.body)['data']

        expect(data['type']).to eq('borrowings')
        expect(data['id']).to be_present
        expect(data['attributes']['status']).to eq('active')
      end

      it 'includes book and reader relationships' do
        create_borrowing

        relationships = JSON.parse(response.body)
                            .dig('data', 'relationships')

        expect(relationships.dig('book', 'data', 'id')).to eq(book.id.to_s)
        expect(relationships.dig('reader', 'data', 'id')).to eq(reader.id.to_s)
      end
    end

    context 'when the book is unavailable' do
      it 'rejects borrowing an already borrowed book' do
        create(:borrowing, book: book)

        create_borrowing

        expect(response).to have_http_status(:conflict)
        expect(JSON.parse(response.body)['errors']).to be_present
      end

      it 'rejects borrowing an archived book' do
        book.update!(archived_at: Time.current)

        create_borrowing

        expect(response).to have_http_status(:conflict)
        expect(JSON.parse(response.body)['errors']).to be_present
      end

      it 'does not create another borrowing' do
        create(:borrowing, book: book)

        expect { create_borrowing }.not_to change(Borrowing, :count)
      end
    end

    context 'with invalid relationships' do
      it 'rejects an incorrect book resource type' do
        payload[:data][:relationships][:book][:data][:type] = 'readers'

        create_borrowing

        expect(response).to have_http_status(:bad_request)
        expect(JSON.parse(response.body)['errors']).to be_present
      end

      it 'rejects a missing reader relationship' do
        payload[:data][:relationships].delete(:reader)

        create_borrowing

        expect(response).to have_http_status(:bad_request)
        expect(JSON.parse(response.body)['errors']).to be_present
      end

      it 'returns 404 when book does not exist' do
        payload[:data][:relationships][:book][:data][:id] = '999999'

        create_borrowing

        expect(response).to have_http_status(:not_found)
      end

      it 'returns 404 when reader does not exist' do
        payload[:data][:relationships][:reader][:data][:id] = '999999'

        create_borrowing

        expect(response).to have_http_status(:not_found)
      end
    end

    context 'with invalid JSON:API payload' do
      it 'rejects an incorrect resource type' do
        payload[:data][:type] = 'books'

        create_borrowing

        expect(response).to have_http_status(:bad_request)
        expect(JSON.parse(response.body)['errors']).to be_present
      end

      it 'rejects a missing data object' do
        post '/api/v1/borrowings',
             params: { book_id: book.id, reader_id: reader.id }.to_json,
             headers: headers

        expect(response).to have_http_status(:bad_request)
        expect(JSON.parse(response.body)['errors']).to be_present
      end
    end
  end

  describe 'POST /api/v1/borrowings/:id/return' do
    it 'returns a borrowed book' do
      borrowing = create(:borrowing)

      post "/api/v1/borrowings/#{borrowing.id}/return",
           headers: headers

      expect(response).to have_http_status(:ok)
      expect(borrowing.reload.returned_at).to be_present
    end

    it 'returns updated borrowing status' do
      borrowing = create(:borrowing)

      post "/api/v1/borrowings/#{borrowing.id}/return",
           headers: headers

      data = JSON.parse(response.body)['data']

      expect(data['type']).to eq('borrowings')
      expect(data['attributes']['status']).to eq('returned')
      expect(data['attributes']['returned_at']).to be_present
    end

    it 'rejects returning an already returned book' do
      borrowing = create(:borrowing, :returned)

      post "/api/v1/borrowings/#{borrowing.id}/return",
           headers: headers

      expect(response).to have_http_status(:conflict)
      expect(JSON.parse(response.body)['errors']).to be_present
    end

    it 'returns 404 for a nonexistent borrowing' do
      post '/api/v1/borrowings/999999/return',
           headers: headers

      expect(response).to have_http_status(:not_found)
    end

    it 'preserves borrowing history after return' do
      borrowing = create(:borrowing)

      expect do
        post "/api/v1/borrowings/#{borrowing.id}/return",
             headers: headers
      end.not_to change(Borrowing, :count)

      expect(borrowing.reload.active?).to be(false)
    end
  end
end
