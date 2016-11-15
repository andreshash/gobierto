class Admin::Admin::InvitationAcceptancesController < Admin::BaseController
  skip_before_action :authenticate_admin!

  layout "admin/sessions"

  def show
    admin = Admin.find_by(invitation_token: params[:invitation_token])

    if admin
      admin.accept_invitation!
      admin.confirm!
      admin.update_session_data(remote_ip)
      sign_in_admin(admin.id)

      # TODO. Redirect to Edit Profile URL to set a new password.
      redirect_to(after_sign_in_path, notice: "Signed in successfully.")
    else
      flash.now[:alert] = "This URL doesn't seem to be valid."
      redirect_to admin_root_path
    end
  end
end