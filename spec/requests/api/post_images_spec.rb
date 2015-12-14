require 'rails_helper'

describe "Post Images API" do

  before(:each) do
    ActionMailer::Base.deliveries = []
  end

  context 'POST /post_images' do

    context "when unauthenticated" do
      it "should return a 401 with a proper error" do
        post "#{host}/post_images", { data: { type: "post_images" } }
        expect(last_response.status).to eq 401
        expect(json).to be_a_valid_json_api_error.with_id "NOT_AUTHORIZED"
      end
    end

    context "when authenticated" do

      let(:gif_string) {
        file = File.open("#{Rails.root}/spec/sample_data/base64_images/gif.txt", 'r')
        open(file) { |io| io.read }
      }

      before do
        @post = create(:post)
        @user = create(:user, email: "test_user@mail.com", password: "password")
        @token = authenticate(email: "test_user@mail.com", password: "password")
      end

      context "with valid data" do
        before do
          params = { data: { type: "post_images",
            attributes: {
              filename: "jake.gif",
              base64_photo_data: gif_string
            },
            relationships: { post: { data: { id: @post.id, type: "posts" } } }
          } }

          authenticated_post "/post_images", params, @token
        end

        it "creates a valid post image" do
          expect(PostImage.last.filename).to eq "jake.gif"
          expect(PostImage.last.user).to eq @user
          expect(PostImage.last.post).to eq @post
        end

        it "notifies Pusher that the upload succeeded" do
          expect(NotifyPusherOfPostImageWorker.jobs.size).to eq 1
        end

        it "responds with a 200" do
          expect(last_response.status).to eq 200
        end

        it "returns the created post image using PostImageSerializer" do
          expect(json).to serialize_object(PostImage.last).with(PostImageSerializer)
        end
      end

      context 'with invalid data' do
        it 'fails when the base 64 string is empty' do
          params = { data: { type: "post_images",
            attributes: {
              filename: "jake.gif"
            },
            relationships: { post: { data: { id: @post.id, type: "posts" } } }
          } }

          authenticated_post "/post_images", params, @token

          expect(last_response.status).to eq 422

          expect(json.errors[0].detail).to eq "Base64 photo data can't be blank"
        end
      end
    end
  end
end