require 'rails_helper'

RSpec.describe "TagTypes", type: :request do
  describe "GET /tag_types" do
    context "when not authenticated" do
      it "redirects to the sign in page" do
        get tag_types_path
        expect(response).to redirect_to(new_session_path)
      end
    end

    context "when authenticated" do
      before { sign_in_as }

      it "returns a successful response and lists tag types" do
        create(:tag_type, name: 'Location')
        get tag_types_path
        expect(response).to have_http_status(:ok)
        expect(response.body).to include('Location')
      end

      it "filters tag types by search term" do
        matching = create(:tag_type, name: 'Location')
        other = create(:tag_type, name: 'Occasion')

        get tag_types_path(search: 'Location')

        expect(response.body).to include(matching.name)
        expect(response.body).not_to include(other.name)
      end
    end
  end

  describe "GET /tag_types/:id/edit" do
    context "as an admin" do
      before { sign_in_as(role: :admin) }

      it "returns a successful response" do
        tag_type = create(:tag_type)
        get edit_tag_type_path(tag_type, locale: 'en')
        expect(response).to have_http_status(:ok)
      end
    end

    context "as an editor" do
      before { sign_in_as(role: :editor) }

      it "is not authorized" do
        tag_type = create(:tag_type)
        get edit_tag_type_path(tag_type, locale: 'en')
        expect(response).to redirect_to(root_path)
      end
    end
  end

  describe "POST /tag_types" do
    context "as an admin" do
      before { sign_in_as(role: :admin) }

      it "creates a tag type" do
        expect {
          post tag_types_path, params: { tag_type: { name_en: 'Location' } }
        }.to change(TagType, :count).by(1)
        expect(TagType.last.name).to eq('Location')
      end

      it "does not create a tag type with a blank name" do
        expect {
          post tag_types_path, params: { tag_type: { name_en: '' } }
        }.not_to change(TagType, :count)
        expect(response).to have_http_status(:unprocessable_entity)
      end
    end

    context "as an editor" do
      before { sign_in_as(role: :editor) }

      it "is not authorized" do
        expect {
          post tag_types_path, params: { tag_type: { name_en: 'Location' } }
        }.not_to change(TagType, :count)
        expect(response).to redirect_to(root_path)
      end
    end
  end

  describe "PATCH /tag_types/:id" do
    context "as an admin" do
      before { sign_in_as(role: :admin) }

      it "updates the tag type" do
        tag_type = create(:tag_type)
        patch tag_type_path(tag_type, locale: 'en'), params: { tag_type: { name_en: 'Updated Name' } }
        expect(tag_type.reload.name).to eq('Updated Name')
        expect(response).to redirect_to(tag_types_path)
      end

      it "does not update with an invalid name" do
        tag_type = create(:tag_type, name: 'Original')
        patch tag_type_path(tag_type, locale: 'en'), params: { tag_type: { name_en: '' } }
        expect(tag_type.reload.name).to eq('Original')
        expect(response).to have_http_status(:unprocessable_entity)
      end
    end

    context "as an editor" do
      before { sign_in_as(role: :editor) }

      it "is not authorized" do
        tag_type = create(:tag_type, name: 'Original')
        patch tag_type_path(tag_type, locale: 'en'), params: { tag_type: { name_en: 'Updated Name' } }
        expect(tag_type.reload.name).to eq('Original')
        expect(response).to redirect_to(root_path)
      end
    end
  end

  describe "DELETE /tag_types/:id" do
    context "as an admin" do
      before { sign_in_as(role: :admin) }

      it "destroys a tag type without tags" do
        tag_type = create(:tag_type)
        expect { delete tag_type_path(tag_type, locale: 'en') }.to change(TagType, :count).by(-1)
      end

      it "does not destroy a tag type that still has tags" do
        tag_type = create(:tag_type)
        create(:tag, name: 'Vacation', tag_type: tag_type)

        expect { delete tag_type_path(tag_type, locale: 'en') }.not_to change(TagType, :count)
      end
    end

    context "as an editor" do
      before { sign_in_as(role: :editor) }

      it "is not authorized" do
        tag_type = create(:tag_type)
        expect { delete tag_type_path(tag_type, locale: 'en') }.not_to change(TagType, :count)
        expect(response).to redirect_to(root_path)
      end
    end
  end
end
