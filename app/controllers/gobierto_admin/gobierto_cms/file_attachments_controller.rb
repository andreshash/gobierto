module GobiertoAdmin
  module GobiertoCms
    class FileAttachmentsController < BaseController
      before_action { module_enabled!(current_site, 'GobiertoCms') }
      before_action { module_allowed!(current_admin, 'GobiertoCms') }

      def index
        @collections = current_site.collections.by_item_type('GobiertoAttachments::Attachment')
        @file_attachments = current_site.attachments.sort_by_updated_at(10)
      end

      def new
        @file_attachment_form = FileAttachmentForm.new(site_id: current_site.id)
      end

      def edit
        @file_attachment = find_file_attachment
        @file_attachment_form = FileAttachmentForm.new(
          @file_attachment.attributes.except(*ignored_file_attachment_attributes)
        )
      end

      def create
        @file_attachment_form = FileAttachmentForm.new(
          file_attachment_params.merge(
            site_id: current_site.id,
            collection: 'gobierto_cms'
          )
        )

        if @file_attachment_form.save
          track_create_activity
          ::GobiertoCommon::Collection.find(params[:file_attachment][:collection_id]).append(@file_attachment_form.file_attachment)

          if params[:file_attachment][:collection_id]
            redirect_to edit_admin_cms_file_attachment_path(@file_attachment_form.file_attachment.id)
          else
            render plain: @file_attachment_form.file_url
          end
        else
          if params[:file_attachment][:collection_id]
            render :edit
          else
            head :bad_request
          end
        end
      end

      def update
        @file_attachment = find_file_attachment
        @file_attachment_form = FileAttachmentForm.new(file_attachment_params.merge(id: @file_attachment.id, site_id: current_site.id))

        if @file_attachment_form.save
          track_update_activity

          redirect_to(
            edit_admin_cms_file_attachment_path(@file_attachment_form.file_attachment.id),
            notice: t(".success_html", link: gobierto_cms_file_attachment_preview_url(@file_attachment_form.file_attachment, host: current_site.domain))
          )
        else
          render :edit
        end
      end

      private

      def track_create_activity
        Publishers::GobiertoAttachmentsAttachmentActivity.broadcast_event("attachment_created", default_activity_params.merge(subject: @file_attachment_form.file_attachment))
      end

      def track_update_activity
        Publishers::GobiertoAttachmentsAttachmentActivity.broadcast_event("attachment_updated", default_activity_params.merge(subject: @file_attachment))
      end

      def default_activity_params
        { ip: remote_ip, author: current_admin, site_id: current_site.id }
      end

      def find_file_attachment
        current_site.attachments.find(params[:id])
      end

      def ignored_file_attachment_attributes
        %w( created_at updated_at id site_id file_size current_version)
      end

      def file_attachment_params
        params.require(:file_attachment).permit(:file, :name, :description, :file_name)
      end
    end
  end
end
