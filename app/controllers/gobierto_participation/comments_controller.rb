# frozen_string_literal: true

module GobiertoParticipation
  class CommentsController < GobiertoParticipation::ApplicationController
    def index
      respond_to do |format|
        format.js
      end
    end

    def create
      @comment_form = CommentForm.new(comment_params.merge(site_id: current_site.id))

      @commentable = find_commentable

      comment_policy = CommentPolicy.new(current_user)
      raise Errors::NotAuthorized unless comment_policy.create?

      @comment_form = CommentForm.new(comment_params.merge(site_id: current_site.id,
                                                           user_id: current_user.id))

      if @comment_form.save
        @contribution = if @comment_form.comment.commentable_type == "GobiertoParticipation::Contribution"
                          @comment_form.comment.commentable
                        else
                          @comment_form.comment.commentable.commentable
                        end
        @comment_form = CommentForm.new(site_id: current_site.id)
      end

      respond_to do |format|
        format.js
      end
    end

    private

    def default_activity_params
      { ip: remote_ip, author: current_admin, site_id: current_site.id }
    end

    def comment_params
      params.require(:comment).permit(
        :body,
        :commentable_id,
        :commentable_type
      )
    end

    def find_commentable
      if params[:commentable_type] == "GobiertoParticipation::Contribution"
        current_site.contributions.find_by!(id: params[:commentable_id])
      elsif params[:commentable_type] == "GobiertoParticipation::Comment"
        current_site.comments.find_by!(id: params[:commentable_id])
      end
    end
  end
end
