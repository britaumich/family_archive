require 'rails_helper'

RSpec.describe "Families", type: :request do
  def sign_in_as(role: :admin)
    user = create(:user, email_address: "#{role}_#{SecureRandom.hex(4)}@example.com", password: 'password')
    create(:admin_user, email: user.email_address, role: role)
    post session_path, params: { email_address: user.email_address, password: 'password' }
    user
  end

  describe "GET /families" do
    context "when not authenticated" do
      it "redirects to the sign in page" do
        get families_path
        expect(response).to redirect_to(new_session_path)
      end
    end

    context "when authenticated" do
      before { sign_in_as }

      it "returns a successful response and lists families" do
        family = create(:family, name: 'Smiths')
        get families_path
        expect(response).to have_http_status(:ok)
        expect(response.body).to include('Smiths')
      end
    end
  end

  describe "GET /families/:id/edit" do
    context "as an admin" do
      before { sign_in_as(role: :admin) }

      it "returns a successful response" do
        family = create(:family)
        get edit_family_path(family, locale: 'en')
        expect(response).to have_http_status(:ok)
      end

      it "filters tags by search term" do
        family = create(:family)
        matching_tag = create(:tag, name: 'Beach')
        other_tag = create(:tag, name: 'Mountains')

        get edit_family_path(family, locale: 'en', search: 'Beach')

        expect(response.body).to include(matching_tag.name)
        expect(response.body).not_to include(other_tag.name)
      end
    end

    context "as an editor" do
      before { sign_in_as(role: :editor) }

      it "is not authorized" do
        family = create(:family)
        get edit_family_path(family, locale: 'en')
        expect(response).to redirect_to(root_path)
      end
    end
  end

  describe "POST /families" do
    context "as an admin" do
      before { sign_in_as(role: :admin) }

      it "creates a family" do
        expect {
          post families_path, params: { family: { name_en: 'Johnsons' } }
        }.to change(Family, :count).by(1)
        expect(Family.last.name).to eq('Johnsons')
      end

      it "does not create a family with a blank name" do
        expect {
          post families_path, params: { family: { name_en: '' } }
        }.not_to change(Family, :count)
        expect(response).to have_http_status(:unprocessable_entity)
      end
    end

    context "as an editor" do
      before { sign_in_as(role: :editor) }

      it "is not authorized" do
        expect {
          post families_path, params: { family: { name_en: 'Johnsons' } }
        }.not_to change(Family, :count)
        expect(response).to redirect_to(root_path)
      end
    end
  end

  describe "PATCH /families/:id" do
    before { sign_in_as(role: :admin) }

    it "updates the family" do
      family = create(:family)
      patch family_path(family, locale: 'en'), params: { family: { name_en: 'Updated Name' } }
      expect(family.reload.name).to eq('Updated Name')
      expect(response).to redirect_to(families_path)
    end

    it "does not update with an invalid name" do
      family = create(:family, name: 'Original')
      patch family_path(family, locale: 'en'), params: { family: { name_en: '' } }
      expect(family.reload.name).to eq('Original')
      expect(response).to have_http_status(:unprocessable_entity)
    end
  end

  describe "DELETE /families/:id" do
    context "as an admin" do
      before { sign_in_as(role: :admin) }

      it "destroys a family without tags" do
        family = create(:family)
        expect { delete family_path(family, locale: 'en') }.to change(Family, :count).by(-1)
      end

      it "does not destroy a family that still has tags" do
        family = create(:family)
        create(:tag, name: 'Vacation', family: family)

        expect { delete family_path(family, locale: 'en') }.not_to change(Family, :count)
      end
    end

    context "as an editor" do
      before { sign_in_as(role: :editor) }

      it "is not authorized" do
        family = create(:family)
        expect { delete family_path(family, locale: 'en') }.not_to change(Family, :count)
        expect(response).to redirect_to(root_path)
      end
    end
  end

  describe "PATCH /families/:id/assign_tags" do
    context "as an admin" do
      before { sign_in_as(role: :admin) }

      it "assigns the given tags to the family" do
        family = create(:family)
        tag = create(:tag, name: 'Vacation')

        patch assign_tags_family_path(family, locale: 'en'), params: { tag_ids: [tag.id] }

        expect(family.reload.tags).to include(tag)
        expect(family.tags_count).to eq(1)
      end

      it "removes tags that are no longer selected" do
        family = create(:family)
        tag = create(:tag, name: 'Vacation', family: family)
        family.update_column(:tags_count, 1)

        patch assign_tags_family_path(family, locale: 'en'), params: { tag_ids: [] }

        expect(family.reload.tags).to be_empty
        expect(family.tags_count).to eq(0)
      end
    end

    context "as an editor" do
      before { sign_in_as(role: :editor) }

      it "is not authorized" do
        family = create(:family)
        tag = create(:tag, name: 'Vacation')

        patch assign_tags_family_path(family, locale: 'en'), params: { tag_ids: [tag.id] }

        expect(family.reload.tags).not_to include(tag)
        expect(response).to redirect_to(root_path)
      end
    end
  end
end
