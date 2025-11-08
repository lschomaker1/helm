class UaojtMailer < ApplicationMailer
  default from: "no-reply@helm-crm.local"  # change to your real sender

  def monthly_sync_result(user, month, log)
    @user  = user
    @month = month
    @log   = log

    subject_prefix = log.success? ? "SUCCESS" : "FAILURE"
    mail(
      to: @user.email,
      subject: "[#{subject_prefix}] UAOJT hours sync for #{@month.strftime('%B %Y')}"
    )
  end
end
