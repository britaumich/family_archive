require 'rails_helper'

RSpec.describe "Items", type: :request do
  describe "GET /items" do
    context "when not authenticated" do
      it "redirects to the sign in page" do
        get items_path
        expect(response).to redirect_to(new_session_path)
      end
    end

    context "when authenticated" do
      before { sign_in_as }

      it "returns a successful response" do
        create(:item, item_type: 'photo')
        get items_path
        expect(response).to have_http_status(:ok)
      end

      it "filters items by item_type" do
        photo = create(:item, item_type: 'photo')
        video = create(:item, item_type: 'video')

        get items_path(item_type: 'video')

        expect(response.body).to include("picture_#{video.id}")
        expect(response.body).not_to include("picture_#{photo.id}")
      end

      it "filters items by a single tag" do
        tag = create(:tag, name: 'Nature')
        matching_item = create(:item)
        matching_item.tags << tag
        other_item = create(:item)

        get items_path(tags: [tag.id])

        expect(response.body).to include("picture_#{matching_item.id}")
        expect(response.body).not_to include("picture_#{other_item.id}")
      end

      it "filters items matching any selected tag by default (OR logic)" do
        tag_a = create(:tag, name: 'Beach')
        tag_b = create(:tag, name: 'Mountains')
        item_a = create(:item).tap { |i| i.tags << tag_a }
        item_b = create(:item).tap { |i| i.tags << tag_b }
        item_c = create(:item)

        get items_path(tags: [tag_a.id, tag_b.id])

        expect(response.body).to include("picture_#{item_a.id}")
        expect(response.body).to include("picture_#{item_b.id}")
        expect(response.body).not_to include("picture_#{item_c.id}")
      end

      it "filters items matching all selected tags when filter_type is 'all'" do
        tag_a = create(:tag, name: 'Beach')
        tag_b = create(:tag, name: 'Mountains')
        item_with_both = create(:item)
        item_with_both.tags << [tag_a, tag_b]
        item_with_one = create(:item).tap { |i| i.tags << tag_a }

        get items_path(tags: [tag_a.id, tag_b.id], filter_type: 'all')

        expect(response.body).to include("picture_#{item_with_both.id}")
        expect(response.body).not_to include("picture_#{item_with_one.id}")
      end

      it "filters items without any tags when no_tags_only is set" do
        tagged_item = create(:item).tap { |i| i.tags << create(:tag, name: 'Tagged') }
        untagged_item = create(:item)

        get items_path(no_tags_only: true)

        expect(response.body).to include("picture_#{untagged_item.id}")
        expect(response.body).not_to include("picture_#{tagged_item.id}")
      end
    end
  end

  describe "GET /items/:id" do
    before { sign_in_as }

    it "returns a successful response" do
      item = create(:item)
      get item_path(item, locale: 'en')
      expect(response).to have_http_status(:ok)
    end
  end

  describe "PATCH /items/:id/assign_tags" do
    let(:item) { create(:item) }
    let(:tag) { create(:tag, name: 'Vacation') }

    context "as an admin" do
      before { sign_in_as(role: :admin) }

      it "assigns the tags to the item" do
        patch assign_tags_item_path(item, locale: 'en'), params: { tag_ids: [tag.id] }
        expect(item.reload.tags).to include(tag)
      end
    end

    context "as an editor" do
      before { sign_in_as(role: :editor) }

      it "is not authorized" do
        patch assign_tags_item_path(item, locale: 'en'), params: { tag_ids: [tag.id] }
        expect(response).to redirect_to(root_path)
      end
    end
  end

  describe "PATCH /items/:id/remove_tags" do
    before { sign_in_as(role: :admin) }

    it "removes the tags from the item" do
      item = create(:item)
      tag = create(:tag, name: 'Vacation')
      item.tags << tag

      patch remove_tags_item_path(item, locale: 'en'), params: { tag_ids: [tag.id] }

      expect(item.reload.tags).not_to include(tag)
    end
  end

  describe "PATCH /items/:id/add_bestof" do
    before { sign_in_as }

    it "toggles the bestof tag on the item" do
      item = create(:item)

      patch add_bestof_item_path(item, locale: 'en')

      expect(item.reload.tags.map(&:name)).to include('bestof')
    end
  end

  describe "DELETE /items/:id" do
    context "as an admin" do
      before { sign_in_as(role: :admin) }

      it "destroys the item" do
        item = create(:item)
        expect { delete item_path(item, locale: 'en') }.to change(Item, :count).by(-1)
        expect(response).to redirect_to(items_path)
      end
    end

    context "as an editor" do
      before { sign_in_as(role: :editor) }

      it "is not authorized to destroy the item" do
        item = create(:item)
        expect { delete item_path(item, locale: 'en') }.not_to change(Item, :count)
        expect(response).to redirect_to(root_path)
      end
    end
  end

  describe "PATCH /items/bulk_assign_tags" do
    before { sign_in_as(role: :admin) }

    it "assigns the given tags to all given items" do
      item_one = create(:item)
      item_two = create(:item)
      tag = create(:tag, name: 'Summer')

      patch bulk_assign_tags_items_path, params: { item_ids: [item_one.id, item_two.id], tag_ids: [tag.id] }

      expect(item_one.reload.tags).to include(tag)
      expect(item_two.reload.tags).to include(tag)
    end
  end

  describe "PATCH /items/bulk_remove_tags" do
    before { sign_in_as(role: :admin) }

    it "removes the given tags from all given items" do
      tag = create(:tag, name: 'Summer')
      item_one = create(:item).tap { |i| i.tags << tag }
      item_two = create(:item).tap { |i| i.tags << tag }

      patch bulk_remove_tags_items_path, params: { item_ids: [item_one.id, item_two.id], tag_ids: [tag.id] }

      expect(item_one.reload.tags).not_to include(tag)
      expect(item_two.reload.tags).not_to include(tag)
    end
  end

  describe "GET /items/editing_tags_page" do
    context "as an admin" do
      before { sign_in_as(role: :admin) }

      it "returns a successful response" do
        get editing_tags_page_items_path
        expect(response).to have_http_status(:ok)
      end
    end

    context "as an editor" do
      before { sign_in_as(role: :editor) }

      it "is not authorized" do
        get editing_tags_page_items_path
        expect(response).to redirect_to(root_path)
      end
    end
  end
end
