class Attachment
  include Mongoid::Document
  include Mongoid::Timestamps::Created

  field :file
  field :file_size
  field :token

  after_initialize do |user|
    self.token ||= SecureRandom.hex(16)
  end

  belongs_to :space
  belongs_to :user

  mount_uploader :file, AttachmentUploader

  before_create :set_file_size
  after_create :inc_user_storage_used
  after_destroy :dec_user_storage_used

  validates_presence_of :file, :user
  validate :check_user_storage_limit, :on => :create

  def set_file_size
    if file.present? && file_changed?
      self.file_size = file.file.size
    end
  end

  def inc_user_storage_used
    user.inc(:storage_used, file_size)
  end

  def dec_user_storage_used
    user.inc(:storage_used, -file_size)
  end

  def check_user_storage_limit
    if file.present? && (user.storage_used + file.file.size > user.storage_limit)
      errors.add(:file, I18n.t('errors.messages.storage_limit'))
    end
  end

  def file_name
    read_attribute :file
  end
end
