# frozen_string_literal: true

require_dependency 'gobierto_participation'

module GobiertoParticipation
  class Poll < ApplicationRecord

    class PollHasAnswers < StandardError; end

    ESTIMATION_MINIMUM_DAYS = 1

    belongs_to :process
    has_many :questions, -> { order(order: :asc) }, class_name: 'GobiertoParticipation::PollQuestion', dependent: :destroy, autosave: true
    has_many :answers, class_name: 'GobiertoParticipation::PollAnswer', autosave: true

    enum visibility_level: { draft: 0, published: 1 }

    scope :open, -> { where("starts_at <= ? AND ends_at >= ?", Time.zone.now, Time.zone.now) }
    scope :answerable, -> { published.open }

    translates :title, :description

    before_save :ensure_editable!

    accepts_nested_attributes_for :questions, allow_destroy: true

    validates_associated :questions, message: I18n.t('activerecord.messages.gobierto_participation/poll.are_not_valid')

    def unique_answers_count
      answers.select('DISTINCT user_id').count
    end

    def men_participation_percentage
      ((men_unique_answers_count * 100) / unique_answers_count).round
    end

    def women_participation_percentage
      100 - men_participation_percentage
    end

    def men_unique_answers_count
      answers.joins(:user).select('DISTINCT user_id').where('users.gender = 0').count
    end

    def women_unique_answers_count
      unique_answers_count - men_unique_answers_count
    end

    def predicted_unique_answers_count
      return unique_answers_count if !answerable?
      return nil if past_days < ESTIMATION_MINIMUM_DAYS

      (length_in_days * average_answers_per_day).round
    end

    def answerable?
      published? && open?
    end

    def results_available?
      published? && closed?
    end

    def answerable_by?(user)
      answerable? && !has_answers_from?(user)
    end

    def has_answers_from?(user)
      answers.where(user: user).any?
    end

    def open?
      Time.zone.now.between?(starts_at, ends_at)
    end

    def closed?
      !open?
    end

    def editable?
      unique_answers_count == 0
    end

    def upcoming?
      starts_at > Time.zone.now
    end

    private

    def ensure_editable!
      raise PollHasAnswers if !editable?
    end

    def past_days
      (Time.zone.now.to_date - starts_at).to_i
    end

    def length_in_days
      (ends_at - starts_at).to_i
    end

    def average_answers_per_day
      (unique_answers_count / past_days.to_f)
    end

  end
end
