# frozen_string_literal: true

module GobiertoAdmin
  class FileAttachmentForm
    include ActiveModel::Model
    prepend ::GobiertoCommon::Trackable

    attr_accessor(
      :id,
      :site_id,
      :admin_id,
      :collection_id,
      :file,
      :file_name,
      :size,
      :file_digest,
      :url,
      :name,
      :description,
      :slug
    )

    delegate :persisted?, to: :file_attachment

    validates :file, presence: true
    validates :site, presence: true

    trackable_on :file_attachment

    notify_changed :name

    def save
      if valid?
        if persisted?
          update_file_attachment
        else
          save_file_attachment
        end
      elsif url
        update_file_attachment
      end
    end

    def site
      @site ||= Site.find_by(id: site_id)
    end

    def admin_id
      @admin_id ||= file_attachment.admin_id
    end

    def file_attachment
      @file_attachment ||= file_attachment_class.find_by(id: id).presence || build_file_attachment
    end
    alias content_context file_attachment

    def url
      @url ||= begin
        return file_attachment.url if file.blank?

        FileUploadService.new(
          site: site,
          collection: file_attachment.model_name.collection,
          attribute_name: :file,
          file: file
        ).call
      end
    end

    private

    def build_file_attachment
      file_attachment_class.new(site_id: site_id)
    end

    def file_attachment_class
      ::GobiertoAttachments::Attachment
    end

    def update_file_attachment
      @file_attachment = file_attachment.tap do |file_attachment_attributes|
        file_attachment_attributes.collection = collection if collection_id
        file_attachment_attributes.site = site
        file_attachment_attributes.admin_id = admin_id
        file_attachment_attributes.name = if name.blank?
                                            if file
                                              file.original_filename
                                            else
                                              file_attachment.name
                                            end
                                          else
                                            name
                                          end
        file_attachment_attributes.description = description
        file_attachment_attributes.slug = slug
      end

      if @file_attachment.valid?
        run_callbacks(:save) do
          @file_attachment.save
        end

        @file_attachment
      else
        promote_errors(@file_attachment.errors)

        false
      end
    end

    def collection_class
      ::GobiertoCommon::Collection
    end

    def save_file_attachment
      @file_attachment = file_attachment.tap do |file_attachment_attributes|
        file_attachment_attributes.collection = collection if collection_id
        file_attachment_attributes.site = site
        file_attachment_attributes.file_name = file.original_filename if file
        file_attachment_attributes.admin_id = admin_id
        file_attachment_attributes.name = if name.blank?
                                            if file
                                              file.original_filename
                                            else
                                              file_attachment.name
                                            end
                                          else
                                            name
                                          end
        file_attachment_attributes.file_size = file.size if file
        file_attachment_attributes.file_digest = ::GobiertoAttachments::Attachment.file_digest(file) if file
        file_attachment_attributes.description = description
        file_attachment_attributes.url = url if url
        file_attachment_attributes.slug = slug
      end

      if @file_attachment.valid?
        run_callbacks(:save) do
          @file_attachment.save
        end

        @file_attachment
      else
        promote_errors(@file_attachment.errors)

        false
      end
    end

    def collection
      @collection ||= collection_class.find_by(id: collection_id)
    end

    protected

    def promote_errors(errors_hash)
      errors_hash.each do |attribute, message|
        errors.add(attribute, message)
      end
    end
  end
end
