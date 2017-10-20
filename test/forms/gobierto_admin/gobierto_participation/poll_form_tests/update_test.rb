# frozen_string_literal: true

require 'test_helper'
require_relative 'base_test'

module GobiertoAdmin
  module GobiertoParticipation
    module PollFormTests
      class UpdateTest < BaseTest

        def user
          @user ||= users(:dennis)
        end

        def poll
          @poll ||= gobierto_participation_polls(:pedestrianization_published)
        end

        def poll_attributes
          @poll_attributes ||= {
            id: poll.id,
            starts_at: poll.starts_at,
            ends_at: poll.ends_at,
            visibility_level: poll.visibility_level,
            title_translations: poll.title_translations,
            description_translations: poll.description_translations,
            questions_attributes: {
              '0' => poll_question_attributes
            },
            process: poll.process
          }
        end

        def poll_question
          @poll_question ||= gobierto_participation_poll_questions(:pedestrianization_open)
        end

        def poll_question_attributes
          @poll_question ||= {
            id: poll_question.id,
            answer_type: poll_question.answer_type,
            order: poll_question.order,
            _destroy: '0',
            title_translations: poll_question.title_translations
          }
        end

        def create_answer_for_poll(poll)
          ::GobiertoParticipation::PollAnswer.create!(
            poll: poll,
            question: poll.questions.first,
            answer_template: nil,
            text: 'Texto de respuesta',
            user: user
          )
        end

        def test_not_editable_when_ansers_exist
          create_answer_for_poll(poll_without_answers)

          poll_form = PollForm.new(poll_without_answers_attributes)

          refute poll_form.save

          assert poll_form.errors.messages.include?(:poll)
          debugger
        end

      end
    end
  end
end