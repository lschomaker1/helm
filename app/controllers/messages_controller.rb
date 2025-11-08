class MessagesController < ApplicationController
  before_action :authenticate_user!

  def create
    @message = Message.new(message_params)
    @message.sender = current_user

    if @message.save
      redirect_back fallback_location: tech_reference_path, notice: "Message sent."
    else
      redirect_back fallback_location: tech_reference_path, alert: "Could not send message."
    end
  end

  private

  def message_params
    params.require(:message).permit(:recipient_id, :subject, :body)
  end
end
