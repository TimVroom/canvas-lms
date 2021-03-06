require_relative '../../helpers/gradebook2_common'

describe "screenreader gradebook" do
  include_context "in-process server selenium tests"
  include Gradebook2Common

  let(:srgb) {"/courses/#{@course.id}/gradebook/change_gradebook_version?version=srgb"}

  def basic_setup(num=1)
    init_course_with_students num
    @course.assignments.create!(
      title: 'Test 1',
      submission_types: 'online_text_entry',
      points_possible: 20,
      grading_type: 'percent'
    )
  end

  it 'can select a student', priority: "1", test_id: 163994 do
    init_course_with_students 2
    @course.assignment_groups.create! name: 'Group 1'
    @course.assignment_groups.create! name: 'Group 2'
    a1 = @course.assignments.create!(
      title: 'Test 1',
      points_possible: 20,
      assignment_group: @course.assignment_groups[0]
    )
    a2 = @course.assignments.create!(
      title: 'Test 2',
      points_possible: 20,
      assignment_group: @course.assignment_groups[1]
    )

    grades = ['15', '12', '11', '3']

    a1.grade_student @students[0], grade: grades[0]
    a1.grade_student @students[1], grade: grades[1]
    a2.grade_student @students[0], grade: grades[2]
    a2.grade_student @students[1], grade: grades[3]

    get srgb

    expect(get_options('#student_select').map(&:text)).to eq ['No Student Selected', @students[0].name, @students[1].name]
    click_option '#student_select', @students[0].name
    expect(ff('#student_information .assignment-group-grade .points').map(&:text)).to eq ["(#{grades[0]} / 20)", "(#{grades[2]} / 20)"]
    click_option '#student_select', @students[1].name
    expect(ff('#student_information .assignment-group-grade .points').map(&:text)).to eq ["(#{grades[1]} / 20)", "(#{grades[3]} / 20)"]
  end

  it 'can select a student using buttons', priority: "1", test_id: 163997 do
    init_course_with_students 3
    get srgb

    before = f('.student_navigation button.previous_object')
    after = f('.student_navigation button.next_object')

    # first student
    expect(before.attribute 'disabled').to be_truthy
    after.click
    expect(f('#student_information .student_selection').text).to eq @students[0].name

    # second student
    after.click
    expect(f('#student_information .student_selection').text).to eq @students[1].name

    # third student
    after.click
    expect(after.attribute 'disabled').to be_truthy
    expect(f('#student_information .student_selection').text).to eq @students[2].name
    expect(before).to eq driver.switch_to.active_element

    # click twice to go back to first student
    before.click
    before.click
    expect(f('#student_information .student_selection').text).to eq @students[0].name
    expect(after).to eq driver.switch_to.active_element
  end

  it 'can select an assignment', priority: "1", test_id: 163998 do
    a1 = basic_setup
    a2 = @course.assignments.create!(
      title: 'Test 2',
      points_possible: 20,
    )

    a1.grade_student @students[0], grade: 14
    get srgb

    expect(get_options('#assignment_select').map(&:text)).to eq ['No Assignment Selected', a1.name, a2.name]
    click_option '#assignment_select', a1.name
    expect(f('#assignment_information .assignment_selection').text).to eq a1.name
    expect(f('#assignment_information').text).to include 'Online text entry'
  end

  it 'updates grade to percentage in percentage grade field', priority: "1", test_id: 163999 do
    skip "Skipped because this spec fails if not run in foreground\n"\
      "This is believed to be the issue: https://code.google.com/p/selenium/issues/detail?id=7346"
    assignment = basic_setup
    get srgb

    click_option '#assignment_select', assignment.name
    click_option '#student_select', @students[0].name
    replace_content f('#student_and_assignment_grade'), "10\t"
    wait_for_ajaximations
    expect(f('#student_and_assignment_grade').attribute 'value').to eq '50%'
  end

  it 'displays/removes warning message for resubmitted assignments', priority: "1", test_id: 164000 do
    skip "Skipped because this spec fails if not run in foreground\n"\
      "This is believed to be the issue: https://code.google.com/p/selenium/issues/detail?id=7346"
    assignment = basic_setup
    user_session @students[0]
    assignment.submit_homework @students[0], submission_type: 'online_text_entry', body: 'Hello!'

    user_session @teacher
    assignment.grade_student @students[0], grade: 12

    user_session @students[0]
    assignment.submit_homework @students[0], submission_type: 'online_text_entry', body: 'Hello again!'

    user_session @teacher
    get srgb
    click_option '#assignment_select', assignment.name
    click_option '#student_select', @students[0].name
    expect(f('p.resubmitted')).to be_displayed

    replace_content f('#student_and_assignment_grade'), "15\t"
    wait_for_ajaximations
    expect(f('p.resubmitted')).to be_nil
  end

  it 'grades match default gradebook grades', priority: "1", test_id: 163994 do
    skip "Skipped because this spec fails if not run in foreground\n"\
      "This is believed to be the issue: https://code.google.com/p/selenium/issues/detail?id=7346"
    a1 = basic_setup
    a2 = @course.assignments.create!(
      title: 'Test 2',
      points_possible: 20
    )

    grades = [15, 12]

    get "/courses/#{@course.id}/gradebook"
    f('.canvas_1 .slick-row .slick-cell').click
    f('.canvas_1 .slick-row .slick-cell .grade').send_keys grades[0], :return

    get srgb
    click_option '#student_select', @students[0].name
    click_option '#assignment_select', a1.name
    expect(f('#student_and_assignment_grade').attribute 'value').to eq grades[0]
    expect(f('#student_information .total-grade').text).to eq "75% (#{grades[0]} / 20 points)"

    click_option '#assignment_select', a2.name
    f('#student_and_assignment_grade').clear
    f('#student_and_assignment_grade').send_keys grades[1], :return
    get "/courses/#{@course.id}/gradebook/change_gradebook_version?version=2"
    expect(f('.canvas_1 .slick-row .slick-cell:nth-of-type(2)').text).to eq grades[1]
  end

  it 'can mute assignments', priority: "1", test_id: 164001 do
    assignment = basic_setup
    get srgb

    click_option '#student_select', @students[0].name
    click_option '#assignment_select', assignment.name
    f('#assignment_muted_check').click
    wait_for_ajaximations
    fj('.ui-dialog:visible button').click
    wait_for_ajaximations

    get "/courses/#{@course.id}/grades/#{@students[0].id}"
    expect(f('.student_assignment.editable').attribute 'data-muted').to eq 'true'

    get "/courses/#{@course.id}/gradebook/change_gradebook_version?version=2"
    expect(fj('.slick-header-columns .slick-header-column:eq(2) a')).to have_class 'muted'
  end

  it 'can unmute assignments', priority: "1", test_id: 288859 do
    assignment = basic_setup
    assignment.mute!

    get srgb
    click_option '#student_select', @students[0].name
    click_option '#assignment_select', assignment.name
    f('#assignment_muted_check').click
    wait_for_ajaximations
    fj('.ui-dialog:visible button').click
    wait_for_ajaximations

    get "/courses/#{@course.id}/grades/#{@students[0].id}"
    expect(f('.student_assignment.editable').attribute 'data-muted').to eq 'false'

    get "/courses/#{@course.id}/gradebook/change_gradebook_version?version=2"
    expect(fj('.slick-header-columns .slick-header-column:eq(2) a')).to_not have_class 'muted'
  end

  it 'can message students who... ', priority: "1", test_id: 164002 do
    basic_setup
    get srgb

    click_option '#assignment_select', 'Test 1'
    f('#message_students').click
    wait_for_ajaximations
    expect(f('#message_students_dialog')).to be_displayed

    f('#body').send_keys 'Hello!'
    fj('.ui-dialog:visible button.send_button').click
    wait_for_ajaximations
    expect(f('#message_students_dialog')).to_not be_displayed
  end

  it 'has total graded submission', priority: "1", test_id: 164003 do
    assignment = basic_setup 2

    assignment.grade_student @students[0], grade: 15
    assignment.grade_student @students[1], grade: 5
    get "/courses/#{@course.id}/gradebook/change_gradebook_version?version=2"
    f('a.assignment_header_drop').click
    fj('#ui-id-18').click

    data = [
      'Average Score: 10',
      'High Score: 15',
      'Low Score: 5',
      'Total Graded Submissions: 2 submissions'
    ]
    expect(f('#assignment-details-dialog-stats-table').text.split /\n/).to eq data

    get srgb
    click_option '#student_select', @students[0].name
    click_option '#assignment_select', assignment.name
    expect(f('#assignment_information p:nth-of-type(2)').text).to eq 'Graded submissions: 2'
    expect(ff('#assignment_information table td').map(&:text)).to eq ['20', '10', '15', '5']
  end

  context 'Group Weights' do
    let(:test_course) { course() }
    let(:teacher)     { user(active_all: true) }
    let(:student)     { user(active_all: true) }
    let!(:enroll_teacher_and_students) do
      test_course.enroll_user(teacher, 'TeacherEnrollment', enrollment_state: 'active')
      test_course.enroll_user(student, 'StudentEnrollment', enrollment_state: 'active')
    end
    let!(:assignment_group_1) { test_course.assignment_groups.create! name: 'Group 1' }
    let!(:assignment_group_2) { test_course.assignment_groups.create! name: 'Group 2' }
    let!(:assignment_1) do
      test_course.assignments.create!(
        title: 'Test 1',
        points_possible: 20,
        assignment_group: assignment_group_1
      )
    end
    let!(:assignment_2) do
      test_course.assignments.create!(
        title: 'Test 2',
        points_possible: 20,
        assignment_group: assignment_group_2
      )
    end

    before(:each) do
      user_session(teacher)
      get "/courses/#{test_course.id}/gradebook/change_gradebook_version?version=srgb"
    end

    it 'should display the group weighting dialog with group weights disabled', priority: "1", test_id: 163995 do
      f('#ag_weights').click
      expect(fj("#assignment_group_weights_dialog table[style='opacity: 0.5;']")).to be_truthy
    end

    it 'should correctly sync group weight settings between srgb and gb2', priority: "1", test_id: 588913 do
      # turn on group weights in srgb
      f('#ag_weights').click
      f('#group_weighting_scheme').click
      f('button .ui-button-text').click

      # go back to gb2 to verify settings stuck
      get "/courses/#{test_course.id}/gradebook/change_gradebook_version?version=2"
      fj('#gradebook_settings').click
      fj('.gradebook_dropdown .ui-menu-item:nth-child(3) a').click

      expect(fj("#assignment_group_weights_dialog table[style='opacity: 1;']")).to be_truthy
    end
  end

  context "as a teacher" do
    before(:each) do
      gradebook_data_setup
    end

    it "should switch to srgb", priority: "1", test_id: 209987 do
      get "/courses/#{@course.id}/gradebook"
      f("#change_gradebook_version_link_holder").click
      expect(f("#not_right_side")).to include_text("Gradebook: Individual View")
      refresh_page
      expect(f("#not_right_side")).to include_text("Gradebook: Individual View")
      f(".span12 a").click
      expect(f("#change_gradebook_version_link_holder")).to be_displayed
    end

    it "Should show sections in drop-down", priority: "1", test_id: 209989 do
      sections=[]
      2.times do |i|
        sections << @course.course_sections.create!(:name => "other section #{i}")
      end

      get srgb

      ui_options = Selenium::WebDriver::Support::Select.new(f("#section_select")).options().map { |option| option.text}
      sections.each do |section|
        expect(ui_options.include? section[:name]).to be_truthy
      end
    end

    it "should focus on accessible elements when setting default grades", priority: "1", test_id: 209991 do
      get "/courses/#{@course.id}/gradebook"
      f("#change_gradebook_version_link_holder").click
      refresh_page
      Selenium::WebDriver::Support::Select.new(f("#assignment_select"))
                                          .select_by(:text, 'second assignment')

      # When the modal opens the close button should have focus
      f("#set_default_grade").click
      focused_classes = driver.execute_script('return document.activeElement.classList')
      expect(focused_classes).to include("ui-dialog-titlebar-close")

      # When the modal closes
      # by setting a grade the "set default grade" button should have focus
      f(".button_type_submit").click
      driver.switch_to.alert.accept
      check_element_has_focus(f "#set_default_grade")

      # by the close button the "set default grade" button should have focus
      f("#set_default_grade").click
      fj('.ui-icon-closethick:visible').click
      check_element_has_focus(f "#set_default_grade")
    end

    describe "Download Submissions Button" do
      let!(:change_first_assignment_to_media_recording) do
        @first_assignment.submission_types = "media_recording"
        @first_assignment.save
      end

      let!(:get_screenreader_gradebook) do
        get srgb
      end
      # The Download Submission button should be displayed for online_upload,
      # online_text_entry, online_url, and online_quiz assignments. It should
      # not be displayed for any other types.
      it "is displayed for online assignments" do
        click_option '#assignment_select', 'second assignment'

        expect(f("#submissions_download_button")).to be_present
      end

      it "is not displayed for assignments which are not submitted online" do
        click_option '#assignment_select', @assignment.name

        expect(f("#submissions_download_button")).to_not be_present
      end
    end
  end
end
