require 'rails_helper'

RSpec.describe "Tags", type: :request do
  def sign_in_as(role: :admin)
    user = create(:user, email_address: "#{role}_#{SecureRandom.hex(4)}@example.com", password: 'password')
    create(:admin_user, email: user.email_address, role: role)
    post session_path, params: { email_address: user.email_address, password: 'password' }
    user
  end

  describe "GET /tags" do
    context "when not authenticated" do
      it "redirects to the sign in page" do
        get tags_path
        expect(response).to redirect_to(new_session_path)
      end
    end

    context "when authenticated" do
      before { sign_in_as }

      it "returns a successful response and lists tags" do
        create(:tag, name: 'Beach')
        get tags_path
        expect(response).to have_http_status(:ok)
        expect(response.body).to include('Beach')
      end

      it "filters tags by search term" do
        matching = create(:tag, name: 'Beach')
        other = create(:tag, name: 'Mountains')

        get tags_path(search: 'Beach')

        expect(response.body).to include(matching.name)
        expect(response.body).not_to include(other.name)
      end
    end
  end

  describe "GET /tags/:id/edit" do
    context "as an admin" do
      before { sign_in_as(role: :admin) }

      it "returns a successful response" do
        tag = create(:tag)
        get edit_tag_path(tag, locale: 'en')
        expect(response).to have_http_status(:ok)
      end
    end

    context "as an editor" do
      before { sign_in_as(role: :editor) }

      it "is not authorized" do
        tag = create(:tag)
        get edit_tag_path(tag, locale: 'en')
        expect(response).to redirect_to(root_path)
      end
    end
  end

  describe "POST /tags" do
    context "as an admin" do
      before { sign_in_as(role: :admin) }

      it "creates a tag" do
        expect {
          post tags_path, params: { tag: { name_en: 'Beach' } }
        }.to change(Tag, :count).by(1)
        expect(Tag.last.name).to eq('Beach')
      end

      it "does not create a tag with a blank name" do
        expect {
          post tags_path, params: { tag: { name_en: '' } }
        }.not_to change(Tag, :count)
        expect(response).to have_http_status(:unprocessable_entity)
      end
    end

    context "as an editor" do
      before { sign_in_as(role: :editor) }

      it "is not authorized" do
        expect {
          post tags_path, params: { tag: { name_en: 'Beach' } }
        }.not_to change(Tag, :count)
        expect(response).to redirect_to(root_path)
      end
    end
  end

  describe "PATCH /tags/:id" do
    context "as an admin" do
      before { sign_in_as(role: :admin) }

      it "updates the tag" do
        tag = create(:tag)
        patch tag_path(tag, locale: 'en'), params: { tag: { name_en: 'Updated Name' } }
        expect(tag.reload.name).to eq('Updated Name')
        expect(response).to redirect_to(tags_path)
      end

      it "does not update with an invalid name" do
        tag = create(:tag, name: 'Original')
        patch tag_path(tag, locale: 'en'), params: { tag: { name_en: '' } }
        expect(tag.reload.name).to eq('Original')
        expect(response).to have_http_status(:unprocessable_entity)
      end
    end

    context "as an editor" do
      before { sign_in_as(role: :editor) }

      it "is not authorized" do
        tag = create(:tag, name: 'Original')
        patch tag_path(tag, locale: 'en'), params: { tag: { name_en: 'Updated Name' } }
        expect(tag.reload.name).to eq('Original')
        expect(response).to redirect_to(root_path)
      end
    end
  end

  describe "DELETE /tags/:id" do
    context "as an admin" do
      before { sign_in_as(role: :admin) }

      it "destroys the tag" do
        tag = create(:tag)
        expect { delete tag_path(tag, locale: 'en') }.to change(Tag, :count).by(-1)
      end
    end

    context "as an editor" do
      before { sign_in_as(role: :editor) }

      it "is not authorized" do
        tag = create(:tag)
        expect { delete tag_path(tag, locale: 'en') }.not_to change(Tag, :count)
        expect(response).to redirect_to(root_path)
      end
    end
  end

  describe "PATCH /tags/bulk_assign" do
    context "as an admin" do
      before { sign_in_as(role: :admin) }

      it "assigns the given tag type to the selected tags" do
        tag_type = create(:tag_type)
        tag_one = create(:tag, name: 'Beach')
        tag_two = create(:tag, name: 'Mountains')

        patch bulk_assign_tags_path, params: { tag_ids: [tag_one.id, tag_two.id], tag_type_id: tag_type.id }

        expect(tag_one.reload.tag_type).to eq(tag_type)
        expect(tag_two.reload.tag_type).to eq(tag_type)
      end
    end

    context "as an editor" do
      before { sign_in_as(role: :editor) }

      it "is not authorized" do
        tag_type = create(:tag_type)
        tag = create(:tag, name: 'Beach')

        patch bulk_assign_tags_path, params: { tag_ids: [tag.id], tag_type_id: tag_type.id }

        expect(tag.reload.tag_type).to be_nil
        expect(response).to redirect_to(root_path)
      end
    end
  end
end
