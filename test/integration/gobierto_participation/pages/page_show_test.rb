# frozen_string_literal: true

require "test_helper"

module GobiertoParticipation
  class PageShowTest < ActionDispatch::IntegrationTest

    def process_path(process)
      gobierto_participation_process_path(process.slug)
    end

    def site
      @site ||= sites(:madrid)
    end

    def gender_violence_process
      @gender_violence_process ||= gobierto_participation_processes(:gender_violence_process)
    end

    def green_city_group
      @green_city_group ||= gobierto_participation_processes(:green_city_group)
    end

    def processes
      @processes ||= [gender_violence_process, green_city_group]
    end

    def test_breadcrumb_items
      with_current_site(site) do
        visit process_path(gender_violence_process)

        within ".global_breadcrumb" do
          assert has_link? "Participation"
          assert has_link? "Processes"
          assert has_link? gender_violence_process.title
        end
      end
    end

    def test_menu_subsections
      with_current_site(site) do
        processes.each do |process|
          visit process_path(process)

          within 'menu.sub_sections' do
            assert has_link? 'Information'
            assert has_link? 'Meetings'

            if process.polls_stage?
              assert has_link? 'Polls'
            else
              refute has_link? 'Polls'
            end

            assert has_link? 'Contributions'
            assert has_link? 'Results'
          end
        end
      end
    end

    def test_secondary_nav
      with_current_site(site) do
        visit process_path(gender_violence_process)

        within "menu.secondary_nav" do
          assert has_link? "News"
          assert has_link? "Agenda"
          assert has_link? "Documents"
          assert has_link? "Activity"
        end
      end
    end

    def test_process_news
      with_current_site(site) do
        visit process_path(gender_violence_process)

        assert_equal gender_violence_process.news.size, all(".place_news-item").size

        news_titles = gender_violence_process.news.map(&:title)

        assert array_match ["Notice 1 title", "Notice 2 title"], news_titles
      end
    end

    def test_process_without_news
      with_current_site(site) do
        visit gobierto_participation_process_path(green_city_group.slug)

        assert has_content? "There are no related news"
      end
    end

    def test_menu_new
      with_current_site(site) do
        visit process_path(gender_violence_process)

        click_link "News"

        assert has_selector?("h2", text: "News")
        click_link "Notice 1 title"
        assert has_selector?("h1", text: "Notice 1 title")
        assert has_content? "Notice 1 body"
      end
    end
  end
end
